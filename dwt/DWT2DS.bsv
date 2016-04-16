import Vector::*;
import Complex::*;
import FixedPoint::*;
import Types::*;
import FShow::*;
import MemTypes::*;
import ClientServer::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;
import MultAdder::*;
import DWT1DS::*;
import BRAMFIFO::*;

/*
Stage 1        Stage 2      Stage 3      Stage 4

e----+------------O----------+------------O
      \          /            \          /
o------O--------+--------------O--------+
      /          \            /          \
e----+------------O----------+------------O
      \          /            \          /
o------O--------+--------------O--------+
      /          \            /          \
e----+------------O----------+------------O
      \          /            \          /
o------O--------+--------------O--------+
      /          \            /          \
e----+------------O----------+------------O
      \          /            \          /
o------O--------+--------------O--------+
*/

(* synthesize *)
module mkDWT1DSFixed(DWT1D#(BLOCK_SIZE));
	DWT1D#(BLOCK_SIZE) m <- mkDWT1DS;
	return m;
endmodule


// n is block size
module mkDWT2DS(DWT1D#(n) dwt1d, DWT2D#(n) ifc) provisos (Add#(1, a__, TMul#(n,TAdd#(WI,WF))), Add#(1, b__, TMul#(TDiv#(n, 2), TAdd#(WI, WF))), Add#(n, n, TMul#(n, 2)), Add#(TDiv#(n,2), TDiv#(n,2), n));
	
	Vector#(6, MultAdder#(n)) multadder;
	multadder[0] <- mkMultAdder(fromReal(cdf97_LiftFilter_a));
	multadder[1] <- mkMultAdder(fromReal(cdf97_LiftFilter_b));
	multadder[2] <- mkMultAdder(fromReal(cdf97_LiftFilter_c));
	multadder[3] <- mkMultAdder(fromReal(cdf97_LiftFilter_d));
	multadder[4] <- mkMultAdder(fromReal(cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));
	
	FIFO#(Vector#(n,WSample)) ofifo <- mkFIFO;
	FIFO#(Size_sample) startqueue <- mkBypassFIFO;
	
	// 12 large fifos 
	Vector#(2,FIFO#(Vector#(n,WSample))) s1fifos <- replicateM(mkSizedBRAMFIFO(valueOf(TDiv#(MAX_SAMPLE,n)) + 2));
	FIFO#(Maybe#(Vector#(n,WSample))) s1signal <- mkPipelineFIFO;
	FIFO#(Vector#(n,WSample)) s1save <- mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n) + 2);
	
	Vector#(2,FIFO#(Vector#(n,WSample))) s2fifos <- replicateM(mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n) + 2));
	FIFO#(Vector#(n,WSample)) s2signal <- mkPipelineFIFO;
	
	Vector#(2,FIFO#(Vector#(n,WSample))) s3fifos <- replicateM(mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n) + 2));
	FIFO#(Maybe#(Vector#(n,WSample))) s3signal <- mkPipelineFIFO;
	FIFO#(Vector#(n,WSample)) s3save <- mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n) + 2);
	
	Vector#(2,FIFO#(Vector#(n,WSample))) s4fifos <- replicateM(mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n) + 2));
	FIFO#(Vector#(n,WSample)) s4signal <- mkPipelineFIFO;
	
	FIFO#(Vector#(TMul#(n,2),WSample)) scfifo <- mkFIFO;
	
	Vector#(8,FIFO#(Vector#(TDiv#(n,2),WSample))) safifos <- replicateM(mkSizedBRAMFIFO(valueOf(MAX_SAMPLE)/valueOf(n)/2 + 2));
	
	Reg#(Size_sample) ln <- mkReg(0);
	Reg#(Size_sample) m2 <- mkReg(0);
	Reg#(Size_sample) sample_fetch <- mkReg(0);
	Reg#(Size_sample) sample_1 <- mkReg(0);	
	Reg#(Size_sample) sample_2 <- mkReg(0);	
	Reg#(Size_sample) sample_3 <- mkReg(0);	
	Reg#(Size_sample) sample_4 <- mkReg(0);	
	Reg#(Size_sample) sample_sc <- mkReg(0);	
	
	Reg#(Size_line) line_fetch <- mkReg(0);
	Reg#(Size_line) line_1 <- mkReg(0);
	Reg#(Size_line) line_2 <- mkReg(0);
	Reg#(Size_line) line_3 <- mkReg(0);
	Reg#(Size_line) line_4 <- mkReg(0);
	Reg#(Size_line) line_sc <- mkReg(0);
	Reg#(Bool) ff_sc <- mkReg(False);
	
	Bool done = (line_fetch == 2*m2 && sample_fetch == 0 && line_1 == m2 && line_2 == m2 && sample_2 == 0 && line_3 == m2 && line_4 == m2 && line_sc == 2*m2);

	rule fetch (line_fetch != 2*m2 && sample_fetch != 0);
		let x <- dwt1d.data.response.get();
`ifdef SIM
		$write("%t DWT2D: DWT1D output %d %d: ", $time, line_fetch, sample_fetch);
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			fxptWrite(4, x[i]);
			$write(" ");
		end
		$display("");
`endif
		if((line_fetch & 1) == 0)begin
			// Even line
			s1fifos[0].enq(x);
			if(line_fetch != 0)
				s1signal.enq(tagged Valid x);
		end
		else begin
			// Odd line
			s1fifos[1].enq(x);
		end
		
		if(sample_fetch == 1)begin
			if(line_fetch + 1 != 2*m2)
				startqueue.enq(ln*fromInteger(valueOf(n)));
			line_fetch <= line_fetch + 1;
			sample_fetch <= ln;
		end
		else begin
			sample_fetch <= sample_fetch - 1;
		end
	endrule
	
	// Feed in last two lines with symmetric extension
	// Since s1signal has depth 1, this rule fires only when it's empty
	rule fetch_last (line_fetch == 2*m2 && sample_fetch != 0);
		s1signal.enq(tagged Invalid);
		sample_fetch <= sample_fetch - 1;
	endrule
	
	(* fire_when_enabled *)
	rule startline;
		startqueue.deq;
		dwt1d.start(startqueue.first); // Start next line
	endrule
	
	rule stage1 (line_1 != m2);
		let a0 = s1fifos[0].first; s1fifos[0].deq;
		let a1 = s1fifos[1].first; s1fifos[1].deq;
		let a2 = fromMaybe(a0, s1signal.first); s1signal.deq;
		
		let c = multadder[0].request(a1, a0, a2);
		
		s2fifos[0].enq(a0);
		s2fifos[1].enq(c);
		
		let x = ?;
		if(line_1 == 0) begin
			// First line, Enque c for symmetric extension
			x = c;
		end
		else begin
			// Use last line
			x = s1save.first; s1save.deq;
		end
		
		s2signal.enq(x); 
		
		s1save.enq(c);
		
		if(sample_1 == 1)begin
			line_1 <= line_1 + 1;
			sample_1 <= ln;
		end
		else begin
			sample_1 <= sample_1 - 1;
		end
		
`ifdef SIM
		$write("%t DWT2D: Stage1 %d %d: ", $time, line_1, sample_1);
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			fxptWrite(4, c[i]);
			$write(" ");
		end
		$display("");
`endif
	endrule
	
	rule stage2 (line_2 != m2 && sample_2 != 0);
		let a0 = s2fifos[0].first; s2fifos[0].deq;
		let a1 = s2fifos[1].first; s2fifos[1].deq;
		let am1 = s2signal.first; s2signal.deq;
		
		let c = multadder[1].request(a0, a1, am1);
		
		s3fifos[0].enq(c);
		s3fifos[1].enq(a1);
		if(line_2 != 0)begin
			// Not first line
			s3signal.enq(tagged Valid c);
		end
		
		if(sample_2 == 1)begin
			line_2 <= line_2 + 1;
			sample_2 <= ln;
		end
		else begin
			sample_2 <= sample_2 - 1;
		end
		
`ifdef SIM
		$write("%t DWT2D: Stage2 %d %d: ", $time, line_2, sample_2);
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			fxptWrite(4, c[i]);
			$write(" ");
		end
		$display("");
`endif
	endrule
	
	rule stage2_last (line_2 == m2 && sample_2 != 0);
		s3signal.enq(tagged Invalid);
		sample_2 <= sample_2 - 1;
	endrule
	
	rule stage3 (line_3 != m2 && sample_3 != 0);
		let a0 = s3fifos[0].first; s3fifos[0].deq;
		let a1 = s3fifos[1].first; s3fifos[1].deq;
		let a2 = fromMaybe(a0, s3signal.first); s3signal.deq;
		
		let c = multadder[2].request(a1, a0, a2);
		
		s4fifos[0].enq(a0);
		s4fifos[1].enq(c);
		
		let x = ?;
		if(line_3 == 0) begin
			// First line, Enque c for symmetric extension
			x = c;
		end
		else begin
			// Use last line
			x = s3save.first; s3save.deq;
		end
		
		s4signal.enq(x); 
		
		s3save.enq(c);
		
		if(sample_3 == 1)begin
			line_3 <= line_3 + 1;
			sample_3 <= ln;
		end
		else begin
			sample_3 <= sample_3 - 1;
		end
		
`ifdef SIM
		$write("%t DWT2D: Stage3 %d %d: ", $time, line_3, sample_3);
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			fxptWrite(4, c[i]);
			$write(" ");
		end
		$display("");
`endif
	endrule
	
	rule stage4 (line_4 != m2 && sample_4 != 0);
		let a0 = s4fifos[0].first; s4fifos[0].deq;
		let a1 = s4fifos[1].first; s4fifos[1].deq;
		let am1 = s4signal.first; s4signal.deq;
		
		let c = multadder[3].request(a0, a1, am1);
		
		scfifo.enq(append(c,a1));
		
		if(sample_4 == 1)begin
			line_4 <= line_4 + 1;
			sample_4 <= ln;
		end
		else begin
			sample_4 <= sample_4 - 1;
		end
		
`ifdef SIM
		$write("%t DWT2D: Stage4 %d %d: ", $time, line_4, sample_4);
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			fxptWrite(4, c[i]);
			$write(" ");
		end
		$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stagesc (!done);
		let a = scfifo.first; scfifo.deq;
		Vector#(n, WSample) a0 = take(a);
		Vector#(n, WSample) a1 = takeTail(a);
		
		let lf = multadder[4].request(replicate(0), replicate(0), a0);
		let hf = multadder[5].request(replicate(0), replicate(0), a1);		
		
		Vector#(TDiv#(n,2), WSample) ll = take(lf);
		Vector#(TDiv#(n,2), WSample) lh = takeTail(lf);
		Vector#(TDiv#(n,2), WSample) hl = take(hf);
		Vector#(TDiv#(n,2), WSample) hh = takeTail(hf);
		
		// Distributor
		if(!ff_sc)begin
			safifos[0].enq(ll);
			safifos[2].enq(lh);
			safifos[4].enq(hl);
			safifos[6].enq(hh);
		end else begin
			safifos[1].enq(ll);
			safifos[3].enq(lh);
			safifos[5].enq(hl);
			safifos[7].enq(hh);
		end
		
		ff_sc <= !ff_sc;
	endrule
	
	rule stagescass (line_sc != 2*m2 && sample_sc != 0);
		
		if((line_sc & 1) == 0) begin
			if(sample_sc > ln/2)begin
				// Output LL
				ofifo.enq(append(safifos[0].first,safifos[1].first));
				safifos[0].deq;
				safifos[1].deq;
			end
			else begin
				// Output LH
				ofifo.enq(append(safifos[2].first,safifos[3].first));
				safifos[2].deq;
				safifos[3].deq;
			end
		end
		else begin
			if(sample_sc > ln/2)begin
				// Output HL
				ofifo.enq(append(safifos[4].first,safifos[5].first));
				safifos[4].deq;
				safifos[5].deq;
			end
			else begin
				// Output HH
				ofifo.enq(append(safifos[6].first,safifos[7].first));
				safifos[6].deq;
				safifos[7].deq;
			end
		end
		
		if(sample_sc == 1)begin
			line_sc <= line_sc + 1;
			sample_sc <= ln;
		end
		else begin
			sample_sc <= sample_sc - 1;
		end
	endrule
	
	rule saydone (done);
		$display("%t DWT2D Done!", $time);
	endrule
	
	interface DWT data;
		interface Put request = dwt1d.data.request;
		interface Get response = toGet(ofifo);
	endinterface

	method Action start(Size_sample l, Size_line m) if (done);
		sample_fetch <= l/fromInteger(valueOf(n));
		sample_1 <= l/fromInteger(valueOf(n));
		sample_2 <= l/fromInteger(valueOf(n));
		sample_3 <= l/fromInteger(valueOf(n));
		sample_4 <= l/fromInteger(valueOf(n));
		sample_sc <= l/fromInteger(valueOf(n));
		
		line_fetch <= 0;
		line_1 <= 0;
		line_2 <= 0;
		line_3 <= 0;
		line_4 <= 0;
		line_sc <= 0;
		ff_sc <= False;
		
		startqueue.enq(l);
		ln <= l/fromInteger(valueOf(n));
		m2 <= m/2;
	endmethod
endmodule
