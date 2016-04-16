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
