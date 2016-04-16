import Vector::*;
import Complex::*;
import FixedPoint::*;
import Types::*;
import FShow::*;
import MemTypes::*;
import ClientServer::*;
import FIFO::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;
import MultAdder::*;


function Vector#(TDiv#(n,2), t) evenArray(Vector#(n, t) a);
	Vector#(TDiv#(n,2), t) b = ?;
	for(Integer i=0; i < valueOf(n)/2; i=i+1)begin
		b[i] = a[2 * i];
	end
	return b;
endfunction

function Vector#(TDiv#(n,2), t) oddArray(Vector#(n, t) a);
	Vector#(TDiv#(n,2), t) b = ?;
	for(Integer i=0; i < valueOf(n)/2; i=i+1)begin
		b[i] = a[2 * i + 1];
	end
	return b;
endfunction


/*
Pipeline Structure:

Input          stage1        stage2          stage3            stage4
         ififo      s1fifo          s2fifo            s3fifo
----+
x0  |
x1  |
x2  |
x3  |     +--+                       +--+                             +--+
x4  +-----+ 0+--------------------+--+ 3+-----------------------+-----+ 6+--------
x5  |     +--+                   /   +--+-+                    /      +--+
x6  |          \                /          \                  /
x7  |           \    +--+      /            \          +--+--+
----+            +---+ 2+-----+              +---------+ 5|-----------------------
x8  |           /    +--+      \             /         +--+--+
x9  |          /                \           /                 \
x10 |         /                  \         /                   \
x11 |     +--+                    \  +--+-+                     \     +--+
x12 +-----+ 1+---------------------+-+ 4+-----------------------++----+ 7+--------
x13 |     +--+                   /   +--+-+                    /      +--+
x14 |          \                /          \                  /
x15 |           \    +--+      /            \          +--+--+
----+            +---+ 3+-----+              +---------+ 6|-----------------------
x16 |           /    +--+      \            /          +--+
x17 |          /                \          /               \
x18 |         /                  \        /                 \
x19 |     +--+                    \  +--++                   \         +--+
x20 +-----+ 2+---------------------+-+ 5+---------------------+--------+ 8+-------
x21 |     +--+                   /   +--+-+                  /         +--+
x22 |          \                /          \                /
x23 |           \    +--+      /            \          +--++
----+            +---+ 4+-----+              +---------+  7+-----------------------
                     ++++                              +---+

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

// n is block size, not actuall sample length
// Fully pipelined
module mkDWT1DS(DWT1D#(n)) provisos(Add#(1, a__, TDiv#(n, 2)), Add#(1, b__, n), Add#(TDiv#(n, 2), TDiv#(n, 2), n));

	Vector#(6, MultAdder#(TDiv#(n,2))) multadder;
	multadder[0] <- mkMultAdder(fromReal(cdf97_LiftFilter_a));
	multadder[1] <- mkMultAdder(fromReal(cdf97_LiftFilter_b));
	multadder[2] <- mkMultAdder(fromReal(cdf97_LiftFilter_c));
	multadder[3] <- mkMultAdder(fromReal(cdf97_LiftFilter_d));
	multadder[4] <- mkMultAdder(fromReal(cdf97_ScaleFactor));
	multadder[5] <- mkMultAdder(fromReal(1/cdf97_ScaleFactor));

	FIFO#(Vector#(n, WSample)) ififo <- mkFIFO;
	FIFO#(Vector#(n, WSample)) ofifo <- mkFIFO;
	
	FIFO#(Vector#(n, WSample)) i1fifo <- mkPipelineFIFO;
	FIFO#(Vector#(n, WSample)) i2fifo <- mkFIFO;
	FIFO#(Maybe#(WSample)) i2xfifo <- mkFIFO;
	
	FIFO#(Vector#(n, WSample)) i25fifo <- mkFIFO;
	FIFO#(Vector#(n, WSample)) i3fifo <- mkPipelineFIFO;
	FIFO#(Vector#(n, WSample)) i4fifo <- mkFIFO;
	FIFO#(Maybe#(WSample)) i4xfifo <- mkFIFO;
	
	FIFO#(Vector#(n, WSample)) iscfifo <- mkFIFO;
	
	Reg#(Size_sample) count1 <- mkReg(0);
	Reg#(Size_sample) count2 <- mkReg(0);
	Reg#(Size_sample) count3 <- mkReg(0);
	Reg#(Size_sample) count4 <- mkReg(0);
	Reg#(Size_sample) countsc <- mkReg(0);
	
	
	Reg#(Maybe#(WSample)) s1save <- mkReg(tagged Invalid);
	Reg#(Maybe#(WSample)) s3save <- mkReg(tagged Invalid);
	
	Bool done = (count1 == 0 && count2 == 0 && count3 == 0 && count4 == 0 && countsc == 0);

    (* fire_when_enabled *)	
	rule feed1;
		//$display("%t Feed 1",$time);
		let x = ififo.first; ififo.deq;
		i1fifo.enq(x);
	endrule
	
	(* fire_when_enabled *)	
	rule feed3;
		//$display("%t Feed 3",$time);
		let x = i25fifo.first; i25fifo.deq;
		i3fifo.enq(x);
	endrule
	
	rule stage1 (count1 != 0);
		//$display("%t DWT1D: Stage 1 count %d",$time, count1);
		let s = i1fifo.first; i1fifo.deq;
		let s0 = evenArray(s);
		let s1 = oddArray(s);
		
		WSample x = ?;
		if(count1 == 1) 
			x = last(s0);
		else
			x = head(ififo.first);
			
		let c = multadder[0].request(s1, s0, shiftInAtN(s0, x));
		
		i2fifo.enq(append(s0,c));
		i2xfifo.enq(s1save);
		s1save <= tagged Valid last(c); // Save last element in stage 1
		count1 <= count1 - 1;
	endrule
	
	rule stage2 (count2 != 0);
		//$display("%t DWT1D: Stage 2 count %d",$time, count2);
		let s = i2fifo.first; i2fifo.deq;
`ifdef SIM
		//$write("%t Result from stage 1: ", $time);
		//for(Integer i=0;i<valueOf(n);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif
		
		Vector#(TDiv#(n,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(n,2), WSample) s1 = takeTail(s); // Odd part
		let x = fromMaybe(head(s1), i2xfifo.first); i2xfifo.deq;
		
		let c = multadder[1].request(s0, s1, shiftInAt0(s1, x));
		
		i25fifo.enq(append(c, s1));
		count2 <= count2 - 1;
	endrule
	
	rule stage3 (count3 != 0);
	
		//$display("%t DWT1D: Stage 3 count %d",$time, count3);
		let s = i3fifo.first; i3fifo.deq;

`ifdef SIM
		//$write("%t Result from stage 2: ", $time);
		//for(Integer i=0;i<valueOf(n);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif
		
		Vector#(TDiv#(n,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(n,2), WSample) s1 = takeTail(s); // Odd part
		
		WSample x = ?;
		if(count3 == 1) 
			x = last(s0);
		else
			x = head(i25fifo.first);
			
		let c = multadder[2].request(s1, s0, shiftInAtN(s0, x));
		
		i4fifo.enq(append(s0,c));
		i4xfifo.enq(s3save);
		s3save <= tagged Valid last(c); // Save last element in stage 1
		count3 <= count3 - 1;
	endrule
	
	rule stage4 (count4 != 0);
	
		//$display("%t DWT1D: Stage 4 count %d",$time, count4);
		let s = i4fifo.first; i4fifo.deq;
		
`ifdef SIM
		//$write("%t Result from stage 3: ", $time);
		//for(Integer i=0;i<valueOf(n);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif
		
		Vector#(TDiv#(n,2), WSample) s0 = take(s); // Even part
		Vector#(TDiv#(n,2), WSample) s1 = takeTail(s); // Odd part
		let x = fromMaybe(head(s1), i4xfifo.first); i4xfifo.deq;
		
		let c = multadder[3].request(s0, s1, shiftInAt0(s1, x));
		
		iscfifo.enq(append(c, s1));
		count4 <= count4 - 1;
	endrule
	
	rule stagesc (countsc != 0);
		//$display("%t DWT1D: Stage sc count %d",$time, countsc);
		let s = iscfifo.first;
`ifdef SIM
		//$write("%t Result from stage 4: ", $time);
		//for(Integer i=0;i<valueOf(n);i=i+1)begin
		//	fxptWrite(7,s[i]);$write(" ");
		//end
		//$display("");
`endif
		Vector#(TDiv#(n,2), WSample) s0 = take(s);
		Vector#(TDiv#(n,2), WSample) s1 = takeTail(s);
		iscfifo.deq;
		
		let lf = multadder[4].request(replicate(0), replicate(0), s0);
		let hf = multadder[5].request(replicate(0), replicate(0), s1);		
		
		countsc <= countsc - 1;
		ofifo.enq(append(lf, hf));
	endrule

	method Action start(Size_sample l) if (done);
		//$display("%t DWT1D: Start",$time);
		
		s1save <= tagged Invalid;
		s3save <= tagged Invalid;
		
		count1 <= l/fromInteger(valueOf(n));
		count2 <= l/fromInteger(valueOf(n));
		count3 <= l/fromInteger(valueOf(n));
		count4 <= l/fromInteger(valueOf(n));
		countsc <= l/fromInteger(valueOf(n));
		
	endmethod
	
	interface DWT data;
		interface Put request = toPut(ififo);
		interface Get response = toGet(ofifo);
	endinterface
endmodule
