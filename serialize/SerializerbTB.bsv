import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;
import Counter::*;

import CommTypes::*;

typedef Server#(
		Bit#(1),
		Byte
		)BitToByte;

(* synthesize *)
module mkSerializerbTB(BitToByte ifc);
   //sizes of these fifos should be played with
   Fifo#(8, Bit#(1)) inputFIFO <- mkCFFifo;
   Fifo#(2, Byte) outputFIFO <- mkCFFifo;

   Vector#(4,Reg#(Bit#(1))) tempBit <- replicateM(mkRegU);
   Reg#(Bit#(3)) bit_count <- mkReg(0);

   rule bytetopixel;
      tempBit[bit_count] <= inputFIFO.first;
      inputFIFO.deq;
      Byte loadByte = 0;
      if (bit_count == 3) begin
	 bit_count <= 0;
	 for (Integer i = 0; i < 3; i=i+1) begin
	    loadByte[i] = tempBit[i];
	 end
	 loadByte[3] = inputFIFO.first;
	 outputFIFO.enq(loadByte);
	 //$display("load byte: ", fshow(loadByte));
      end
      else begin
	 bit_count <= bit_count + 1;
      end
   endrule

   interface Put request;
      method Action put(Bit#(1) x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule

