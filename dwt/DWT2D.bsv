import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;
import MultAdder::*;
import DWT1D::*;
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


// p is block size
// n is # of samples in each line
// m is # of lines in total
module mkDWT2DP(DWT1D#(n, p) dwt1d, DWT2D#(n, m, p) ifc) provisos (Add#(1, a__, TMul#(p,TAdd#(WI,WF))), Add#(1, b__, TMul#(TDiv#(p, 2), TAdd#(WI, WF))), Add#(1, c__, p), Add#(1, d__, TDiv#(p, 2)), Add#(TDiv#(p,2), TDiv#(p,2), p));
	
	Integer np = valueOf(n)/valueOf(p);
	Integer m2 = valueOf(m)/2;
	
	Vector#(6, MultAdder#(p)) multadder;
	multadder[0] <- mkMultAdder(fromReal(cdf97_LiftFilter_a));
	multadder[1] <- mkMultAdder(fromReal(cdf97_LiftFilter_b));
	multadder[2] <- mkMultAdder(fromReal(cdf97_LiftFilter_c));
	multadder[3] <- mkMultAdder(fromReal(cdf97_LiftFilter_d));
	multadder[4] <- mkMultAdder(fromReal(cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));
	
	FIFO#(Vector#(p,WSample)) ofifo <- mkFIFO;
	
	// 12 large fifos 
	Vector#(2,FIFO#(Vector#(p,WSample))) s1fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s1signal <- mkPipelineFIFO;
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s2fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s2save <- mkSizedBRAMFIFO(np + 2);
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s3fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s3signal <- mkPipelineFIFO;
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s4fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s4save <- mkSizedBRAMFIFO(np + 2);
	
	FIFO#(Vector#(TAdd#(p,p),WSample)) scfifo <- mkFIFO;
	
	Vector#(8,FIFO#(Vector#(TDiv#(p,2),WSample))) safifos <- replicateM(mkSizedBRAMFIFO(np/2 + 2));
	
	Reg#(Size_t#(n)) sample_fetch <- mkReg(0);
	Reg#(Size_t#(n)) sample_1 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_2 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_3 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_4 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_sc <- mkReg(0);	
	
	Reg#(Size_t#(m)) line_fetch <- mkReg(0);
	Reg#(Size_t#(m)) line_1 <- mkReg(0);
	Reg#(Size_t#(m)) line_2 <- mkReg(0);
	Reg#(Size_t#(m)) line_3 <- mkReg(0);
	Reg#(Size_t#(m)) line_4 <- mkReg(0);
	Reg#(Size_t#(m)) line_sc <- mkReg(0);
	Reg#(Bool) ff_sc <- mkReg(False);
	Reg#(Bool) ff_ass <- mkReg(False);
	
	(* fire_when_enabled *)
	rule fetch;
		let x <- dwt1d.response.get();
		
		if((line_fetch & 1) == 0)begin
			s1fifos[0].enq(x);
			if(line_fetch != 0)
				s1signal.enq(x);
		end
		else begin
			s1fifos[1].enq(x);
		end
		
		if(sample_fetch == fromInteger(np-1))begin
			line_fetch <= (line_fetch == fromInteger(valueOf(m)-1)) ? 0 : line_fetch + 1;
			sample_fetch <= 0;
		end
		else begin
			sample_fetch <= sample_fetch + 1;
		end
		
`ifdef SIM
		//$write("%t DWT2D %d: DWT1D output: %d %d: ", $time, valueOf(n), line_fetch, sample_fetch);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, x[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage1;
		
		let a0 = s1fifos[0].first; s1fifos[0].deq;
		let a1 = s1fifos[1].first; s1fifos[1].deq;
		let a2 = ?;
	
		if(line_1 == fromInteger(m2)-1)begin
			a2 = a0;
		end
		else begin
			a2 = s1signal.first; s1signal.deq;
		end
		
		let c = multadder[0].request(a1, a0, a2);
		
		s2fifos[0].enq(a0);
		s2fifos[1].enq(c);
		
		if(sample_1 == fromInteger(np-1))begin
			line_1 <= (line_1 == fromInteger(m2-1)) ? 0 : line_1 + 1;
			sample_1 <= 0;
		end
		else begin
			sample_1 <= sample_1 + 1;
		end
		
`ifdef SIM
		//$write("%t DWT2D %d: Stage1 %d %d: ", $time, valueOf(n), line_1, sample_1);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage2;
		let a0 = s2fifos[0].first; s2fifos[0].deq;
		let a1 = s2fifos[1].first; s2fifos[1].deq;
		let am1 = ?;
		
		if(line_2 == 0)begin
			am1 = a1;
		end
		else begin
			am1 = s2save.first; s2save.deq;
		end
		
		if(line_2 != fromInteger(m2-1))
			s2save.enq(a1);
		
		let c = multadder[1].request(a0, am1, a1);
		
		s3fifos[0].enq(c);
		s3fifos[1].enq(a1);
		if(line_2 != 0)
			s3signal.enq(c);
		
		if(sample_2 == fromInteger(np-1))begin
			line_2 <= (line_2 == fromInteger(m2-1)) ? 0 : line_2 + 1;
			sample_2 <= 0;
		end
		else begin
			sample_2 <= sample_2 + 1;
		end
		
`ifdef SIM
		//$write("%t DWT2D %d: Stage2 %d %d: ", $time, valueOf(n), line_2, sample_2);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule

	(* fire_when_enabled *)
	rule stage3;
		
		let a0 = s3fifos[0].first; s3fifos[0].deq;
		let a1 = s3fifos[1].first; s3fifos[1].deq;
		let a2 = ?;
	
		if(line_3 == fromInteger(m2)-1)begin
			a2 = a0;
		end
		else begin
			a2 = s3signal.first; s3signal.deq;
		end
		
		let c = multadder[2].request(a1, a0, a2);
		
		s4fifos[0].enq(a0);
		s4fifos[1].enq(c);
		
		if(sample_3 == fromInteger(np-1))begin
			line_3 <= (line_3 == fromInteger(m2-1)) ? 0 : line_3 + 1;
			sample_3 <= 0;
		end
		else begin
			sample_3 <= sample_3 + 1;
		end
		
`ifdef SIM
		//$write("%t DWT2D %d: Stage3 %d %d: ", $time, valueOf(n), line_3, sample_3);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage4;
		let a0 = s4fifos[0].first; s4fifos[0].deq;
		let a1 = s4fifos[1].first; s4fifos[1].deq;
		let am1 = ?;
		
		if(line_4 == 0)begin
			am1 = a1;
		end
		else begin
			am1 = s4save.first; s4save.deq;
		end
		
		if(line_4 != fromInteger(m2-1))
			s4save.enq(a1);
		
		let c = multadder[3].request(a0, am1, a1);
		
		scfifo.enq(append(c,a1));
		
		if(sample_4 == fromInteger(np-1))begin
			line_4 <= (line_4 == fromInteger(m2-1)) ? 0 : line_4 + 1;
			sample_4 <= 0;
		end
		else begin
			sample_4 <= sample_4 + 1;
		end
		
`ifdef SIM
		//$write("%t DWT2D %d: Stage4 %d %d: ", $time, valueOf(n), line_4, sample_4);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stagesc;
		let a = scfifo.first; scfifo.deq;
		Vector#(p, WSample) a0 = take(a);
		Vector#(p, WSample) a1 = takeTail(a);
		
		let lf = multadder[4].request(replicate(0), replicate(0), a0);
		let hf = multadder[5].request(replicate(0), replicate(0), a1);		
		
		Vector#(TDiv#(p,2), WSample) ll = take(lf);
		Vector#(TDiv#(p,2), WSample) lh = takeTail(lf);
		Vector#(TDiv#(p,2), WSample) hl = take(hf);
		Vector#(TDiv#(p,2), WSample) hh = takeTail(hf);
		
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
	
	(* fire_when_enabled *)
	rule stagescass;
		
		if(np > 1)begin
			if((line_sc & 1) == 0) begin
				if(sample_sc < fromInteger(np/2))begin
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
				if(sample_sc < fromInteger(np/2))begin
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
		end
		else begin
			// When there is only one block per line, we just assemble it as how it was disassembled
			// $display("%t NP=1, ff_ass=%b", $time, ff_ass);
			if(!ff_ass)begin
				if((line_sc & 1) == 0) begin
					// Output LL+LH
					ofifo.enq(append(safifos[0].first, safifos[2].first));
					safifos[0].deq;
					safifos[2].deq;
				end
				else begin
					// Output HL+HH
					ofifo.enq(append(safifos[4].first, safifos[6].first));
					safifos[4].deq;
					safifos[6].deq;
					ff_ass <= !ff_ass;
				end
			end
			else begin
				if((line_sc & 1) == 0) begin
					// Output LL+LH
					ofifo.enq(append(safifos[1].first, safifos[3].first));
					safifos[1].deq;
					safifos[3].deq;
				end
				else begin
					// Output HL+HH
					ofifo.enq(append(safifos[5].first, safifos[7].first));
					safifos[5].deq;
					safifos[7].deq;
					ff_ass <= !ff_ass;
				end
			end
		end
		
		
		if(sample_sc == fromInteger(np - 1))begin
			line_sc <= (line_sc == fromInteger(valueOf(m)-1)) ? 0 : line_sc + 1;
			sample_sc <= 0;
		end
		else begin
			sample_sc <= sample_sc + 1;
		end
	endrule
	
	interface Put request = dwt1d.request;
	interface Get response = toGet(ofifo);

endmodule



/************************************************************************************/
// p is block size
// n is # of samples in each line
// m is # of lines in total
module mkIDWT2DP(DWT1D#(n, p) idwt1d, DWT2D#(n, m, p) ifc) provisos (Add#(1, a__, TMul#(p,TAdd#(WI,WF))), Add#(1, b__, TMul#(TDiv#(p, 2), TAdd#(WI, WF))), Add#(1, c__, p), Add#(1, d__, TDiv#(p, 2)), Add#(TDiv#(p,2), TDiv#(p,2), p));
	
	Integer np = valueOf(n)/valueOf(p);
	Integer m2 = valueOf(m)/2;
	
	Vector#(6, MultAdder#(p)) multadder;
	multadder[0] <- mkMultAdder(fromReal(-cdf97_LiftFilter_d));
	multadder[1] <- mkMultAdder(fromReal(-cdf97_LiftFilter_c));
	multadder[2] <- mkMultAdder(fromReal(-cdf97_LiftFilter_b));
	multadder[3] <- mkMultAdder(fromReal(-cdf97_LiftFilter_a));
	multadder[4] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(cdf97_ScaleFactor));
	
	FIFO#(Vector#(p,WSample)) ififo <- mkFIFO;
	
	// 12 large fifos 
	Vector#(2,FIFO#(Vector#(p,WSample))) s1fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s1save <- mkSizedBRAMFIFO(np + 2);
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s2fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s2signal <- mkPipelineFIFO;
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s3fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s3save <- mkSizedBRAMFIFO(np + 2);
	
	Vector#(2,FIFO#(Vector#(p,WSample))) s4fifos <- replicateM(mkSizedBRAMFIFO(np + 2));
	FIFO#(Vector#(p,WSample)) s4signal <- mkPipelineFIFO;
	
	FIFO#(Vector#(TAdd#(p,p),WSample)) scfifo <- mkFIFO;
	
	Vector#(8,FIFO#(Vector#(TDiv#(p,2),WSample))) srfifos <- replicateM(mkSizedBRAMFIFO(np/2 + 2));
	
	Reg#(Size_t#(n)) sample_re <- mkReg(0);
	Reg#(Size_t#(n)) sample_1 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_2 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_3 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_4 <- mkReg(0);	
	Reg#(Size_t#(n)) sample_sc <- mkReg(0);	
	
	Reg#(Size_t#(m)) line_re <- mkReg(0);
	Reg#(Size_t#(m)) line_1 <- mkReg(0);
	Reg#(Size_t#(m)) line_2 <- mkReg(0);
	Reg#(Size_t#(m)) line_3 <- mkReg(0);
	Reg#(Size_t#(m)) line_4 <- mkReg(0);
	Reg#(Size_t#(m)) line_sc <- mkReg(0);
	Reg#(Bool) ff_re <- mkReg(False);
	Reg#(Bool) ff_ass <- mkReg(False);
	
	(* fire_when_enabled *)
	rule scale;
		let x = ififo.first; ififo.deq;
		
		// Scale
		let c=?;
		if((line_sc & 1) == 0)begin
			c = multadder[4].request(replicate(0), replicate(0), x);
			s1fifos[0].enq(c);
		end
		else begin
			c = multadder[5].request(replicate(0), replicate(0), x);
			s1fifos[1].enq(c);
		end
		
		if(sample_sc == fromInteger(np-1))begin
			line_sc <= (line_sc == fromInteger(valueOf(m)-1)) ? 0 : line_sc + 1;
			sample_sc <= 0;
		end
		else begin
			sample_sc <= sample_sc + 1;
		end
		
`ifdef SIM
		//$write("%t IDWT2D %d: Stage scale: %d %d: ", $time, valueOf(n), line_sc, sample_sc);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage1;
		
		let a0 = s1fifos[0].first; s1fifos[0].deq;
		let a1 = s1fifos[1].first; s1fifos[1].deq;
		let am1 = ?;
		
		if(line_1 == 0)begin
			am1 = a1;
		end
		else begin
			am1 = s1save.first; s1save.deq;
		end
		
		if(line_1 != fromInteger(m2-1))
			s1save.enq(a1);
		
		let c = multadder[0].request(a0, am1, a1);
		
		s2fifos[0].enq(c);
		s2fifos[1].enq(a1);
		if(line_1 != 0)
			s2signal.enq(c);
		
		if(sample_1 == fromInteger(np-1))begin
			line_1 <= (line_1 == fromInteger(m2-1)) ? 0 : line_1 + 1;
			sample_1 <= 0;
		end
		else begin
			sample_1 <= sample_1 + 1;
		end
		
`ifdef SIM
		//$write("%t IDWT2D %d: Stage1 %d %d: ", $time, valueOf(n), line_1, sample_1);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage2;
		let a0 = s2fifos[0].first; s2fifos[0].deq;
		let a1 = s2fifos[1].first; s2fifos[1].deq;
		let a2 = ?;
	
		if(line_2 == fromInteger(m2)-1)begin
			a2 = a0;
		end
		else begin
			a2 = s2signal.first; s2signal.deq;
		end
		
		let c = multadder[1].request(a1, a0, a2);
		
		s3fifos[0].enq(a0);
		s3fifos[1].enq(c);
		
		if(sample_2 == fromInteger(np-1))begin
			line_2 <= (line_2 == fromInteger(m2-1)) ? 0 : line_2 + 1;
			sample_2 <= 0;
		end
		else begin
			sample_2 <= sample_2 + 1;
		end
		
`ifdef SIM
		//$write("%t IDWT2D %d: Stage2 %d %d: ", $time, valueOf(n), line_2, sample_2);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule

	(* fire_when_enabled *)
	rule stage3;
		
		let a0 = s3fifos[0].first; s3fifos[0].deq;
		let a1 = s3fifos[1].first; s3fifos[1].deq;
		let am1 = ?;
		
		if(line_3 == 0)begin
			am1 = a1;
		end
		else begin
			am1 = s3save.first; s3save.deq;
		end
		
		if(line_3 != fromInteger(m2-1))
			s3save.enq(a1);
		
		let c = multadder[2].request(a0, am1, a1);
		
		s4fifos[0].enq(c);
		s4fifos[1].enq(a1);
		if(line_3 != 0)
			s4signal.enq(c);
		
		if(sample_3 == fromInteger(np-1))begin
			line_3 <= (line_3 == fromInteger(m2-1)) ? 0 : line_3 + 1;
			sample_3 <= 0;
		end
		else begin
			sample_3 <= sample_3 + 1;
		end
		
`ifdef SIM
		///$write("%t IDWT2D %d: Stage3 %d %d: ", $time, valueOf(n), line_3, sample_3);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stage4;
		let a0 = s4fifos[0].first; s4fifos[0].deq;
		let a1 = s4fifos[1].first; s4fifos[1].deq;
		let a2 = ?;
	
		if(line_4 == fromInteger(m2)-1)begin
			a2 = a0;
		end
		else begin
			a2 = s4signal.first; s4signal.deq;
		end
		
		let c = multadder[3].request(a1, a0, a2);
		
		if(np > 1)begin
			if(sample_4 < fromInteger(np/2)) begin
				// LF component in each line
				srfifos[0].enq(take(a0));
				srfifos[2].enq(takeTail(a0));
				srfifos[4].enq(take(c));
				srfifos[6].enq(takeTail(c));
			end
			else begin
				// HF component in each line
				srfifos[1].enq(take(a0));
				srfifos[3].enq(takeTail(a0));
				srfifos[5].enq(take(c));
				srfifos[7].enq(takeTail(c));
			end
		end
		else begin
			// No distribution
			srfifos[0].enq(take(a0));
			srfifos[2].enq(takeTail(a0));
			srfifos[4].enq(take(c));
			srfifos[6].enq(takeTail(c));
		end
		
		if(sample_4 == fromInteger(np-1))begin
			line_4 <= (line_4 == fromInteger(m2-1)) ? 0 : line_4 + 1;
			sample_4 <= 0;
		end
		else begin
			sample_4 <= sample_4 + 1;
		end
		
		
`ifdef SIM
		//$write("%t IDWT2D %d: Stage4 %d %d: ", $time, valueOf(n), line_4, sample_4);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(4, c[i]);
		//	$write(" ");
		//end
		//$display("");
`endif
	endrule
	
	(* fire_when_enabled *)
	rule stagereorder;
		
		if(np > 1)begin
			if((line_re & 1) == 0) begin
				// Output Even line
				if(!ff_re)begin
					idwt1d.request.put(append(srfifos[0].first,srfifos[1].first));
					srfifos[0].deq;
					srfifos[1].deq;
				end
				else begin
					idwt1d.request.put(append(srfifos[2].first,srfifos[3].first));
					srfifos[2].deq;
					srfifos[3].deq;
				end
			end
			else begin
				if(!ff_re)begin
					// Output odd line
					idwt1d.request.put(append(srfifos[4].first,srfifos[5].first));
					srfifos[4].deq;
					srfifos[5].deq;
				end
				else begin
					// Output odd line
					idwt1d.request.put(append(srfifos[6].first,srfifos[7].first));
					srfifos[6].deq;
					srfifos[7].deq;
				end
			end
			
			ff_re <= !ff_re;
		end
		else begin
			// When there is only one block per line, we just assemble it as how it was disassembled
			if((line_re & 1) == 0) begin
				// Output even line mixed LF/HF
				idwt1d.request.put(append(srfifos[0].first, srfifos[2].first));
				srfifos[0].deq;
				srfifos[2].deq;
			end
			else begin
				// Output odd line mixed LF/HF
				idwt1d.request.put(append(srfifos[4].first, srfifos[6].first));
				srfifos[4].deq;
				srfifos[6].deq;
			end
		end
		
		
		if(sample_re == fromInteger(np - 1))begin
			line_re <= (line_re == fromInteger(valueOf(m)-1)) ? 0 : line_re + 1;
			sample_re <= 0;
		end
		else begin
			sample_re <= sample_re + 1;
		end
	endrule
	
	interface Put request = toPut(ififo);
	interface Get response = idwt1d.response;

endmodule

module mkDWT2D(DWT2D#(n, m, p)) provisos (Add#(1, a__, TMul#(p,TAdd#(WI,WF))), Add#(1, b__, TMul#(TDiv#(p, 2), TAdd#(WI, WF))), Add#(1, c__, p), Add#(1, d__, TDiv#(p, 2)), Add#(TDiv#(p,2), TDiv#(p,2), p));
	DWT1D#(n,p) dwt1d <- mkDWT1D();
	DWT2D#(n,m,p) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

module mkIDWT2D(DWT2D#(n, m, p)) provisos (Add#(1, a__, TMul#(p,TAdd#(WI,WF))), Add#(1, b__, TMul#(TDiv#(p, 2), TAdd#(WI, WF))), Add#(1, c__, p), Add#(1, d__, TDiv#(p, 2)), Add#(TDiv#(p,2), TDiv#(p,2), p));
	DWT1D#(n,p) idwt1d <- mkIDWT1D();
	DWT2D#(n,m,p) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule
