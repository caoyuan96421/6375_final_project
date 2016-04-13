import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;

import CommTypes::*;

typedef Server#(
		Pixel,
		Line
		)PixelToList;
		  

(* synthesize *)
module mkSerializerPTL(PixelToMemWord ifc);
   //sizes of these fifos should be played with
   Fifo#(2, Pixel) inputFIFO <- mkCFFifo;
   Fifo#(2, Line) outputFIFO <- mkCFFifo;

   Vector#(16,Reg#(Pixel)) tempLine <- replicateM(mkRegU);
   Reg#(Bit#(5)) pixel_count <- mkReg(0);
   Reg#(Bit#(24)) addr <- mkReg(0);
   //this rule could be folded
   rule pixeltoword;
      tempLine[pixel_count] <= inputFIFO.first;
      inputFIFO.deq;
      MemData loadData = 0;
      if (pixel_count == 31) begin
	 pixel_count <= 0;
	 addr <= addr + 1;
	 
	 for (Integer i = 0; i < 31; i=i+1) begin
	    for (Integer j = 0; j < 6; j=j+1) begin
	       loadLine[(24*i)+(4*(j+1)-1):24*i+4*j] = tempLine[i][j];
	    end
	 end
	 for (Integer k = 0; k < 6; k=k+1) begin
	    loadLine[744+(4*(k+1)-1):(744+4*k)] = inputFIFO.first[k];
	 end
	 outputFIFO.enq(loadLine);
      end
      else begin
	 pixel_count <= pixel_count + 1;
      end
   endrule

   interface Put request;
      method Action put(Pixel x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule

