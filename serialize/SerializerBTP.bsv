import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;
import Counter::*;

import CommTypes::*;

typedef Server#(
		Byte,
		Pixel
		)BytesToPixel;

(* synthesize *)
module mkSerializerBTP(BytesToPixel ifc);
   //sizes of these fifos should be played with
   Fifo#(2, Byte) inputFIFO <- mkCFFifo;
   Fifo#(2, Pixel) outputFIFO <- mkCFFifo;

   Vector#(6,Reg#(Byte)) tempPixel <- replicateM(mkRegU);
   Reg#(Bit#(3)) byte_count <- mkReg(0);

   rule bytetopixel;
      tempPixel[byte_count] <= inputFIFO.first;
      inputFIFO.deq;
      Pixel loadPixel = replicate(0);
      if (byte_count == 5) begin
	 byte_count <= 0;
	 for (Integer i = 0; i < 5; i=i+1) begin
	    loadPixel[i] = tempPixel[i];
	 end
	 loadPixel[5] = inputFIFO.first;
	 outputFIFO.enq(loadPixel);
	 //$display("load pixel: ", fshow(loadPixel));
      end
      else begin
	 byte_count <= byte_count + 1;
      end
   endrule

   interface Put request;
      method Action put(Byte x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule

