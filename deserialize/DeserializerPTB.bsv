import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;
import Counter::*;

import CommTypes::*;

typedef Server#(
		Pixel,
		Byte
		)PixelToByte;

(* synthesize *)
module mkDeserializerPTB(PixelToByte ifc);
   //sizes of these fifos should be played with
   Fifo#(12, Pixel) inputFIFO <- mkCFFifo;
   Fifo#(2, Byte) outputFIFO <- mkCFFifo;

   Reg#(Pixel) tempPixel <- mkRegU;
   Reg#(Bit#(3)) byte_count <- mkReg(0);
   Reg#(Bool) processed <- mkReg(True);

   rule pixelload (processed);
      tempPixel <= inputFIFO.first;
      inputFIFO.deq;
      processed <= False;
   endrule

   rule byteextract (!processed);
      outputFIFO.enq(tempPixel[byte_count]);
      if (byte_count == 5) begin
	 byte_count <= 0;
     processed <= True;
      end
      else begin
	 byte_count <= byte_count + 1;
      end
   endrule

   interface Put request;
      method Action put(Pixel x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule
