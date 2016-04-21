import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;

import CommTypes::*;

typedef Server#(
		//Byte,
		Bit#(1),
		//Vector#(p,Coeff)
		Coeff
		)Decode; //#(numeric type p);


function Bool can_write (Vector#(63,Reg#(Maybe#(Bit#(1)))) bitBuffer,Reg#(Bit#(6)) w_index);
   if (isValid(bitBuffer[w_index])) begin
      return False;
   end
   else begin
      if (w_index + 4 < 63) begin
	 if (isValid(bitBuffer[w_index + 4])) return False;
	 else return True;
      end
      else begin
	 
	 if (isValid(bitBuffer[w_index + 4-63])) return False;
	 else return True;
      end
   end
endfunction

function Bool can_read (Vector#(63,Reg#(Maybe#(Bit#(1)))) bitBuffer,Reg#(Bit#(6)) r_index);
   if (isValid(bitBuffer[r_index])) begin
      return False;
   end
   else begin
      if (r_index + 22 < 63) begin
	 if (isValid(bitBuffer[r_index + 22])) return False;
	 else return True;
      end
      else begin
	 
	 if (isValid(bitBuffer[r_index + 22-63])) return False;
	 else return True;
      end
   end
endfunction

//(* synthesize *)
module mkDecoder(Decode ifc);
   FIFO#(Bit#(1)) inputFIFO <- mkFIFO;
   FIFO#(Coeff) outputFIFO <- mkFIFO; //do need another chunker?
   //integer of full precision
   Vector#(16,Reg#(Bit#(1))) storedBits <- replicateM(mkReg(0));
   Reg#(Bit#(5)) numberBits <- mkReg(0);
   Reg#(Bool) oneNext <- mkReg(False);
   Reg#(Bool) twoNext <- mkReg(False);
   Reg#(Bool) threeNext <- mkReg(False);
/*
   Vector#(63,Reg#(Maybe#(Bit#(1)))) bitBuffer <- replicateM(mkReg(Invalid));
   Reg#(Bit#(6)) w_index <- mkReg(0);
   Reg#(Bit#(6)) r_index <- mkReg(0);
   FIFO#(Coeff) toVectFIFO <- mkFIFO;
   Reg#(Bit#(TLog#(p))) count <- mkReg(0);
   Vector#(p,Reg#(Coeff)) storeVect <- replicateM(mkReg(0));

   //conflicts with buffer_read, we make writes higher priority
   (* descending_urgency = "loadbyte, getCoeff" *)
   rule loadbyte (can_write(bitBuffer,w_index));
      let load = inputFIFO.first;
      inputFIFO.deq;
      for (Integer i = 0; i < 4; i=i+1) begin
	 bitBuffer[w_index+fromInteger(i)] <= tagged Valid load[i];
      end
      if (w_index + 4 > 63) begin
	 w_index <= w_index + 4 - 63;
      end
      else begin
	 w_index <= w_index + 4;
      end
   endrule

   rule getCoeff (can_read(bitBuffer,r_index));
      let newBit_0 = fromMaybe(?,bitBuffer[r_index]);
      let newBit_1 = fromMaybe(?,bitBuffer[r_index+1]);
      let newBit_2 = fromMaybe(?,bitBuffer[r_index+2]);
      let newBit_3 = fromMaybe(?,bitBuffer[r_index+3]);
      let newBit_4 = fromMaybe(?,bitBuffer[r_index+4]);
      let newBit_5 = fromMaybe(?,bitBuffer[r_index+5]);
      Coeff in = 0;
      if (newBit_1 == 0) begin
	 in = 0;
	 //toVectFIFO.enq(in);
	 for (Integer i = 0; i < 2; i=i+1) begin
	    bitBuffer[r_index + fromInteger(i)] <= tagged Invalid;
	 end
      end
      else begin
	 if (newBit_2 == 0) begin
	    if (newBit_3 == 0) begin
	       in = 1;
	    end
	    else begin
	       in = -1;
	    end
	    for (Integer i = 0; i < 4; i=i+1) begin
	       bitBuffer[r_index + fromInteger(i)] <= tagged Invalid;
	    end
	 end
	 else begin
	    if (newBit_3 == 0) begin
	       if (newBit_4 == 0) begin
		  in = 2;
	       end
	       else begin
		  in = -2;
	       end
	       for (Integer i = 0; i < 5; i=i+1) begin
		  bitBuffer[r_index + fromInteger(i)] <= tagged Invalid;
	       end
	    end
	    else begin
	       for (Integer i = 0; i < 6; i=i+1) begin
		  bitBuffer[r_index + fromInteger(i)] <= tagged Invalid;
	       end
	       if (newBit_4 == 0) begin
		  if (newBit_5 == 0) begin
		     in = 3;
		  end
		  else begin
		     in = -3;
		  end
	       end
	       else begin
		  if (newBit_5 == 0) begin
		     in = -4;
		  end
		  else begin
		     Bit#(16) tempCoeff = 0;
		     for (Integer i = 0; i < 16; i=i+1) begin
			tempCoeff[i] = fromMaybe(?,bitBuffer[r_index + 6 + fromInteger(i)]);
			bitBuffer[r_index + 6 + fromInteger(i)] <= tagged Invalid;
		     end
		     Int#(16) tC = unpack(tempCoeff);
		     in = fromInt(tC);
		  end
	       end
	    end
	 end
      end
      toVectFIFO.enq(in);
   endrule

   rule toVect;
      let newCoeff = toVectFIFO.first;
      toVectFIFO.deq;
      Vector#(p,Coeff) outVect = replicate(0);
      if (count == fromInteger(valueOf(TSub#(p,1)))) begin
	 for (Integer i = 0; i < valueOf(TSub#(p,1)); i=i+1) begin
	    outVect[i] = storeVect[i];
	 end
	 outVect[fromInteger(valueOf(TSub#(p,1)))] = newCoeff;
	 outputFIFO.enq(outVect);
	 count <= 0;
      end
      else begin
	 storeVect[count] <= newCoeff;
	 count <= count + 1;
      end
   endrule
    */  
      
   
   rule loadbit;
      let newBit = inputFIFO.first;
      inputFIFO.deq;
      Bit#(5) tempNumberBits = 0;
      Coeff x = 0;
      /*$display("new bit:", newBit);
      $display("number bits:", numberBits);*/
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
	    //$display("decode:%d",x);
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
      ///$display("temp number bits:", tempNumberBits);
      //$display("x", x);
      numberBits <= tempNumberBits;
      if (tempNumberBits == 0) begin
	 //$display("here");
	 outputFIFO.enq(x);
      end
   endrule
   
   interface Put request = toPut(inputFIFO);
   interface Get response = toGet(outputFIFO);
      
endmodule
