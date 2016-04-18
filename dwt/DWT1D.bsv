import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import FIFO::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;
import MultAdder::*;

/*
DWT 1D module, with fixed # of samples in each line, specified in the initialization of the interface
*/

function Vector#(TDiv#(m,2), t) evenArray(Vector#(m, t) a);
	Vector#(TDiv#(m,2), t) b = ?;
	for(Integer i=0; i < valueOf(m)/2; i=i+1)begin
		b[i] = a[2 * i];
	end
	return b;
endfunction

function Vector#(TDiv#(m,2), t) oddArray(Vector#(m, t) a);
	Vector#(TDiv#(m,2), t) b = ?;
	for(Integer i=0; i < valueOf(m)/2; i=i+1)begin
		b[i] = a[2 * i + 1];
	end
	return b;
endfunction

function Vector#(m, t) zip01(Vector#(TDiv#(m,2), t) a, Vector#(TDiv#(m,2), t) b);
	Vector#(m, t) c = ?;
	for(Integer i=0; i < valueOf(m)/2; i=i+1)begin
		c[2*i] = a[i];
		c[2*i+1] = b[i];
	end
	return c;
endfunction

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

// p is block size, 
// n is # of samples in a line
// Fully pipelined
module mkDWT1D(DWT1D#(n,p)) provisos(Add#(1, a__, TDiv#(p, 2)), Add#(1, b__, p), Add#(TDiv#(p, 2), TDiv#(p, 2), p));

	Integer np=valueOf(TDiv#(n,p));

	Vector#(6, MultAdder#(TDiv#(p,2))) multadder;
	multadder[0] <- mkMultAdder(fromReal(cdf97_LiftFilter_a));
	multadder[1] <- mkMultAdder(fromReal(cdf97_LiftFilter_b));
	multadder[2] <- mkMultAdder(fromReal(cdf97_LiftFilter_c));
	multadder[3] <- mkMultAdder(fromReal(cdf97_LiftFilter_d));
	multadder[4] <- mkMultAdder(fromReal(cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));

	FIFO#(Vector#(p, WSample)) ififo <- mkFIFO;
	FIFO#(Vector#(p, WSample)) ofifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) i1fifo <- mkPipelineFIFO;
	FIFO#(Vector#(p, WSample)) i2fifo <- mkFIFO;
	FIFO#(WSample) i2xfifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) i25fifo <- mkFIFO;
	FIFO#(Vector#(p, WSample)) i3fifo <- mkPipelineFIFO;
	FIFO#(Vector#(p, WSample)) i4fifo <- mkFIFO;
	FIFO#(WSample) i4xfifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) iscfifo <- mkFIFO;
	
	Reg#(Size_t#(n)) count1 <- mkReg(fromInteger(np-1));
	Reg#(Size_t#(n)) count2 <- mkReg(0);
	Reg#(Size_t#(n)) count3 <- mkReg(fromInteger(np-1));
	Reg#(Size_t#(n)) count4 <- mkReg(0);
	
	Reg#(WSample) s1save <- mkRegU;
	Reg#(WSample) s3save <- mkRegU;

    (* fire_when_enabled *)	
	rule feed1;
`ifdef SIM
		//$display("%t Feed 1",$time);
`endif
		let x = ififo.first; ififo.deq;
		i1fifo.enq(x);
	endrule
	
	(* fire_when_enabled *)	
	rule feed3;
`ifdef SIM
		//$display("%t Feed 3",$time);
`endif
		let x = i25fifo.first; i25fifo.deq;
		i3fifo.enq(x);
	endrule
	
	rule stage1;
`ifdef SIM
		//$display("%t DWT1D: Stage 1 count %d",$time, count1);
`endif
		let s = i1fifo.first; i1fifo.deq;
		let s0 = evenArray(s);
		let s1 = oddArray(s);
		
		WSample x = ?;
		if(count1 == 0) 
			x = last(s0);
		else
			x = head(ififo.first);
			
		let c = multadder[0].request(s1, s0, shiftInAtN(s0, x));
		
		i2fifo.enq(append(s0,c));
		i2xfifo.enq(s1save);
		s1save <= last(c); // Save last element in stage 1
		
		count1 <= (count1 == 0) ? fromInteger(np-1) : count1 - 1;
	endrule
	
	rule stage2;

		let s = i2fifo.first; i2fifo.deq;
		
`ifdef SIM
		//$display("%t DWT1D: Stage 2 count %d",$time, count2);
		//$write("%t Result from stage 1: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		let x = (count2 == 0) ? head(s1) : i2xfifo.first; i2xfifo.deq;
		
		let c = multadder[1].request(s0, s1, shiftInAt0(s1, x));
		
		i25fifo.enq(append(c, s1));
		
		count2 <= (count2 == fromInteger(np-1)) ? 0 : count2 + 1;
	endrule
	
	rule stage3;

		let s = i3fifo.first; i3fifo.deq;
		
`ifdef SIM
		//$display("%t DWT1D: Stage 3 count %d",$time, count3);
		//$write("%t Result from stage 2: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		
		WSample x = ?;
		if(count3 == 0) 
			x = last(s0);
		else
			x = head(i25fifo.first);
			
		let c = multadder[2].request(s1, s0, shiftInAtN(s0, x));
		
		i4fifo.enq(append(s0,c));
		i4xfifo.enq(s3save);
		s3save <= last(c); // Save last element in stage 1
		
		count3 <= (count3 == 0) ? fromInteger(np-1) : count3 - 1;
	endrule
	
	rule stage4;
		
		let s = i4fifo.first; i4fifo.deq;
		
`ifdef SIM
		//$display("%t DWT1D: Stage 4 count %d",$time, count4);
		//$write("%t Result from stage 3: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		let x = (count4 == 0) ? head(s1) : i4xfifo.first; i4xfifo.deq;
		
		let c = multadder[3].request(s0, s1, shiftInAt0(s1, x));
		
		iscfifo.enq(append(c, s1));
		
		count4 <= (count4 == fromInteger(np-1)) ? 0 : count4 + 1;
	endrule
	
	rule stagesc;

		let s = iscfifo.first;
		
`ifdef SIM
		//$display("%t DWT1D: Stage sc",$time);
		//$write("%t Result from stage 4: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s);
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s);
		iscfifo.deq;
		
		let lf = multadder[4].request(replicate(0), replicate(0), s0);
		let hf = multadder[5].request(replicate(0), replicate(0), s1);		
		
		ofifo.enq(append(lf, hf));
	endrule
	
	interface Put request = toPut(ififo);
	interface Get response = toGet(ofifo);
endmodule

/*******************************************************************************************************/
// p is block size, 
// n is # of samples in a line
// Fully pipelined
module mkIDWT1D(DWT1D#(n,p)) provisos(Add#(1, a__, TDiv#(p, 2)), Add#(1, b__, p), Add#(TDiv#(p, 2), TDiv#(p, 2), p));

	Integer np=valueOf(TDiv#(n,p));

	Vector#(6, MultAdder#(TDiv#(p,2))) multadder;
	multadder[0] <- mkMultAdder(fromReal(-cdf97_LiftFilter_d));
	multadder[1] <- mkMultAdder(fromReal(-cdf97_LiftFilter_c));
	multadder[2] <- mkMultAdder(fromReal(-cdf97_LiftFilter_b));
	multadder[3] <- mkMultAdder(fromReal(-cdf97_LiftFilter_a));
	multadder[4] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(cdf97_ScaleFactor));

	FIFO#(Vector#(p, WSample)) ififo <- mkFIFO;
	FIFO#(Vector#(p, WSample)) ofifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) i1fifo <- mkFIFO;
	FIFO#(WSample) i1xfifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) i15fifo <- mkFIFO;
	FIFO#(Vector#(p, WSample)) i2fifo <- mkPipelineFIFO;
	
	FIFO#(Vector#(p, WSample)) i3fifo <- mkFIFO;
	FIFO#(WSample) i3xfifo <- mkFIFO;
	
	FIFO#(Vector#(p, WSample)) i35fifo <- mkFIFO;
	FIFO#(Vector#(p, WSample)) i4fifo <- mkPipelineFIFO;
	
	Reg#(Size_t#(n)) count1 <- mkReg(0);
	Reg#(Size_t#(n)) count2 <- mkReg(fromInteger(np-1));
	Reg#(Size_t#(n)) count3 <- mkReg(0);
	Reg#(Size_t#(n)) count4 <- mkReg(fromInteger(np-1));

    (* fire_when_enabled *)	
	rule feed2;
`ifdef SIM
		//$display("%t Feed 2",$time);
`endif
		let x = i15fifo.first; i15fifo.deq;
		i2fifo.enq(x);
	endrule
	
	(* fire_when_enabled *)	
	rule feed4;
`ifdef SIM
		//$display("%t Feed 4",$time);
`endif
		let x = i35fifo.first; i35fifo.deq;
		i4fifo.enq(x);
	endrule
	
	rule stagesc;
		let s = ififo.first; ififo.deq;
		
`ifdef SIM
		//$display("%t IDWT1D: Stage sc",$time);
		//$write("%t Result from IDWT2D: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) lf = take(s); // LF part
		Vector#(TDiv#(p,2), WSample) hf = takeTail(s); // HF part
		
		let s0 = multadder[4].request(replicate(0), replicate(0), lf);
		let s1 = multadder[5].request(replicate(0), replicate(0), hf);	
		
		i1fifo.enq(append(s0, s1));
	endrule
	
	rule stage1;
		let s = i1fifo.first; i1fifo.deq;
		
`ifdef SIM
		//$display("%t IDWT1D: Stage 1 count %d",$time, count1);
		//$write("%t Result from stage sc: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		///	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // LF part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // HF part
		let x = ?;
		if(count1 == 0)
			x = head(s1);
		else begin
			x = i1xfifo.first;
			i1xfifo.deq;
		end
		
		if(count1 != fromInteger(np-1))
			i1xfifo.enq(last(s1));
		
		let c = multadder[0].request(s0, s1, shiftInAt0(s1, x));
		
		i15fifo.enq(append(c, s1));
		
		count1 <= (count1 == fromInteger(np-1)) ? 0 : count1 + 1;
	endrule
	
	rule stage2;

		let s = i2fifo.first; i2fifo.deq;
		
`ifdef SIM
		//$display("%t IDWT1D: Stage 2 count %d",$time, count2);
		//$write("%t Result from stage 1: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		
		WSample x = ?;
		if(count2 == 0) 
			x = last(s0);
		else
			x = head(i15fifo.first);
			
		let c = multadder[1].request(s1, s0, shiftInAtN(s0, x));
		
		i3fifo.enq(append(s0,c));
		
		count2 <= (count2 == 0) ? fromInteger(np-1) : count2 - 1;
	endrule
	
	rule stage3;

		let s = i3fifo.first; i3fifo.deq;
		
`ifdef SIM
		//$display("%t IDWT1D: Stage 3 count %d",$time, count3);
		//$write("%t Result from stage 2: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		
		let x = ?;
		if(count3 == 0)
			x = head(s1);
		else begin
			x = i3xfifo.first;
			i3xfifo.deq;
		end
		
		if(count3 != fromInteger(np-1))
			i3xfifo.enq(last(s1));
		
		let c = multadder[2].request(s0, s1, shiftInAt0(s1, x));
		
		i35fifo.enq(append(c, s1));
		
		count3 <= (count3 == fromInteger(np-1)) ? 0 : count3 + 1;
		
	endrule
	
	rule stage4;
		let s = i4fifo.first; i4fifo.deq;
		
`ifdef SIM
		//$display("%t IDWT1D: Stage 4 count %d",$time, count4);
		//$write("%t Result from stage 3: ", $time);
		//for(Integer i=0;i<valueOf(p);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif

		Vector#(TDiv#(p,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(p,2), WSample) s1 = takeTail(s); // Odd part
		
		WSample x = ?;
		if(count4 == 0) 
			x = last(s0);
		else
			x = head(i35fifo.first);
			
		let c = multadder[3].request(s1, s0, shiftInAtN(s0, x));
		
		ofifo.enq(zip01(s0,c));
		
		count4 <= (count4 == 0) ? fromInteger(np-1) : count4 - 1;
	endrule
	
	interface Put request = toPut(ififo);
	interface Get response = toGet(ofifo);
endmodule
