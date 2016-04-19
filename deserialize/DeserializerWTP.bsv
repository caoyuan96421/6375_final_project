import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;

import CommTypes::*;

typedef Server#(
		MemData,
		Pixel
		)MemDataToPixel;
		  

(* synthesize *)
module mkDeserializerWTP(MemDataToPixel ifc);
   //sizes of these fifos should be played with
   Fifo#(32, MemData) inputFIFO <- mkCFFifo;
   Fifo#(2, Pixel) outputFIFO <- mkCFFifo;

   Reg#(MemWord) word <- mkRegU;
   Reg#(Bit#(4)) pixel_count <- mkReg(0);
   Reg#(Bool) processed <- mkReg(True);
   //this rule could be folded.
   rule wordload (processed);
      let tempData = inputFIFO.first;
      MemWord tempWord = replicate(replicate(0));
     for (Integer i = 0; i < 16; i=i+1) begin
	    for (Integer j = 0; j < 6; j=j+1) begin
	       tempWord[i][j] = tempData[(24*i)+(4*(j+1)-1):24*i+4*j];
	    end
	 end
      word <= tempWord;
      inputFIFO.deq;
      processed <= False;
   endrule

   rule pixelextract (!processed);
      outputFIFO.enq(word[pixel_count]);
      if (pixel_count == 15) begin
	 pixel_count <= 0;
     processed <= True;
      end
      else begin
	 pixel_count <= pixel_count + 1;
      end
   endrule

   interface Put request;
      method Action put(MemData x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule
