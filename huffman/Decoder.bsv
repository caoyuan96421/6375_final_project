import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;

import CommTypes::*;

typedef Server#(
		Bit#(1),
		Coeff
		)Decode;

(* synthesize *)
module mkDecoder(Decode ifc);
   FIFO#(Bit#(1)) inputFIFO <- mkFIFO;
   FIFO#(Coeff) outputFIFO <- mkFIFO; //do need another chunker?
   //integer of full precision
   Vector#(16,Reg#(Bit#(1))) storedBits <- replicateM(mkReg(0));
   Reg#(Bit#(5)) numberBits <- mkReg(0);
   Reg#(Bool) oneNext <- mkReg(False);
   Reg#(Bool) twoNext <- mkReg(False);
   Reg#(Bool) threeNext <- mkReg(False);

   rule loadbit;
      let newBit = inputFIFO.first;
      inputFIFO.deq;
      Bit#(5) tempNumberBits = 0;
      Coeff x = 0;
      $display("new bit:", newBit);
      $display("number bits:", numberBits);
      case (numberBits)
	 5'd0: 
	 begin
	    tempNumberBits = 1;
	 end
	 5'd1: 
	 begin
	    if (newBit == 0) begin
	       x = 0;
	       tempNumberBits = 0;
	    end
	    else begin
	       tempNumberBits = 2;
	    end
	 end
	 5'd2:
	 begin
	    if (newBit == 0) begin
	       oneNext <= True;
	    end
	    tempNumberBits = 3;
	 end
	 5'd3:
	 begin
	    if(oneNext) begin
	       if (newBit == 0) begin 
		  x = 1;
	       end
	       else begin
		  x = -1;
	       end
	       tempNumberBits = 0;
	       oneNext <= False;
	    end
	    else begin
	       if (newBit == 0) begin
		  twoNext <= True;
	       end
	       tempNumberBits = 4;
	    end
	 end
	 5'd4:
	 begin
	    if (twoNext) begin
	       if (newBit == 0) begin 
		  x = 2;
	       end
	       else begin
		  x = -2;
	       end
	       tempNumberBits = 0;
	       twoNext <= False;
	    end
	    else begin
	       if (newBit == 0) begin
		  threeNext <= True;
	       end
	       tempNumberBits = 5;	     
	    end
	 end
	 5'd5:
	 begin
	    if(threeNext) begin
	       if (newBit == 0) begin
		  x = 3;
	       end
	       else begin
		  x = -3;
	       end
	       threeNext <= False;
	       tempNumberBits = 0;
	    end
	    else begin
	       if (newBit == 0) begin
		  x = -4;
		  tempNumberBits = 0;
	       end
	       else begin
		  tempNumberBits = 6;
	       end
	    end
	 end
	 5'd21:
	 begin
	    Bit#(16) out = 0;
	    for (Integer i=0;i<15;i=i+1) begin
	       out[i] = storedBits[i];
	    end 
	    out[15] = newBit;
	    x = unpack(truncate(out));
	    $display("decode:%d",x);
	     //will prob have type problems
	    //$display("bits:%b,int:%d,fp:",out,iout,fshow(x));
	    tempNumberBits = 0;
	 end
	 default:
	 begin
	    tempNumberBits = numberBits + 1;
	    storedBits[numberBits - 6] <= newBit; //will prob have type problems
	 end
      endcase
      //$display("number bits:", numberBits);
      //$display("temp number bits:", tempNumberBits);
      //$display("x", x);
      numberBits <= tempNumberBits;
      if (tempNumberBits == 0) begin
	 //$display("here");
	 outputFIFO.enq(x);
      end
   endrule
   
   interface Put request;
      method Action put (Bit#(1) x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);
      
endmodule
