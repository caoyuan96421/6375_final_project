import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;
import Counter::*;

import CommTypes::*;

typedef Server#(
		Byte,
		Bit#(1)
		)ByteToBit;

(* synthesize *)
module mkDeserializerBTb(ByteToBit ifc);
   //sizes of these fifos should be played with
   Fifo#(2, Byte) inputFIFO <- mkCFFifo;
   Fifo#(8, Bit#(1)) outputFIFO <- mkCFFifo;

   Reg#(Byte) tempByte <- mkRegU;
   Reg#(Bit#(2)) bit_count <- mkReg(0);
   Reg#(Bool) processed <- mkReg(True);

   rule pixelload (processed);
      tempByte <= inputFIFO.first;
      inputFIFO.deq;
      processed <= False;
   endrule

   rule byteextract (!processed);
      outputFIFO.enq(tempByte[bit_count]);
      if (bit_count == 3) begin
	 bit_count <= 0;
	 processed <= True;
      end
      else begin
	 bit_count <= bit_count + 1;
      end
   endrule

   interface Put request;
      method Action put(Byte x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule
