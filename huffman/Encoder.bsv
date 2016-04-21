import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;

import CommTypes::*;

typedef struct {
        Bit#(6) size;
	Bit#(6) value;
        Bit#(16) coeff;
        } Encoding  deriving (Bits,Eq);

typedef Server#(
		Vector#(p,Coeff),
		Byte
		)Encode#(numeric type p);

function Bool can_write (Vector#(64,Reg#(Maybe#(Bit#(1)))) bitBuffer,Reg#(Bit#(6)) w_index);
   if (isValid(bitBuffer[w_index])) begin
      return False;
   end
   else begin
      if (w_index + 22 < 63) begin
	 if (isValid(bitBuffer[w_index + 22])) return False;
	 else return True;
      end
      else begin
	 
	 if (isValid(bitBuffer[w_index + 22-63])) return False;
	 else return True;
      end
   end
endfunction

function Bool can_read (Vector#(64,Reg#(Maybe#(Bit#(1)))) bitBuffer,Reg#(Bit#(6)) r_index);
   if (isValid(bitBuffer[r_index])) begin
      if (r_index + 3 < 63) begin
	 if (isValid(bitBuffer[r_index + 3])) return True;
	 else return False;
      end
      else begin
	 //return True;
	 if (isValid(bitBuffer[r_index + 3-63])) return True;
	 else return False;
      end
   end
   else begin
      return False;
   end
endfunction

//(* synthesize *)
module mkEncoder(Encode#(p) ifc);
   FIFO#(Vector#(p,Coeff)) inputFIFO <- mkFIFO;
   FIFO#(Byte) outputFIFO <- mkFIFO; //scaled so that 2*p coeffs = 11*p bytes
   Reg#(Bit#(6)) coeff_count <- mkReg(0);
   Reg#(Bit#(6)) count <- mkReg(0);
   Reg#(Bit#(6)) maxCountReg <- mkReg(0);
   Reg#(Bit#(6)) valueReg <- mkReg(0);
   Reg#(Bit#(16)) coeffReg <- mkReg(0);
   Reg#(Vector#(p,Encoding)) currEncoding <- mkRegU;
   FIFO#(Vector#(p,Encoding)) encodingFIFO <- mkFIFO; //this fifo should also change size
   Vector#(64,Reg#(Maybe#(Bit#(1)))) bitBuffer <- replicateM(mkReg(Invalid));
   Reg#(Bit#(6)) w_index <- mkReg(0);
   Reg#(Bit#(6)) r_index <- mkReg(0);
   

   rule map2encoding;
      Vector#(p,Encoding) encoding;
      for (Integer i = 0; i <  valueof(p); i=i+1) begin
	 let inCoeff = inputFIFO.first[i];
	 //$display("coeff in:",inCoeff);
	 Bit#(16) inCoeffB = extend(pack(inCoeff));
	 //values are backward here so read forward at end.
	 //coeffs should be fipped on the decoder side.
	 case (inCoeff)
	    0: encoding[i] = Encoding{size:2,value:6'b000001, coeff: ?};       
	    1: encoding[i] = Encoding{size:4,value:6'b000011, coeff: ?};
	    -1:encoding[i] = Encoding{size:4,value:6'b001011, coeff: ?};
	    2: encoding[i] = Encoding{size:5,value:6'b000111, coeff: ?};
	    -2:encoding[i] = Encoding{size:5,value:6'b010111, coeff: ?};
	    3: encoding[i] = Encoding{size:6,value:6'b001111, coeff: ?};
	    -3:encoding[i] = Encoding{size:6,value:6'b101111, coeff: ?};
	    -4:encoding[i] = Encoding{size:6,value:6'b011111, coeff: ?};
	    default:encoding[i] = Encoding{size:22,value:6'b111111, coeff:inCoeffB};
	 endcase
      end
      //$display("encoding vector:",encoding);
      inputFIFO.deq;
      encodingFIFO.enq(encoding);
      
   endrule
/*
   rule bitChunk;
      let currEncoding = encodingFIFO.first; //don't remove until done with data
      let maxCount = currEncoding.size;
      if (count != maxCount) begin
	 if (count < 6) begin
            outputFIFO.enq(currEncoding.value[count]);
	 end
	 else begin
	    outputFIFO.enq(currEncoding.coeff[count-6]);
	 end
         count <= count + 1;
      end
      else begin   
         encodingFIFO.deq;
         count <= 0;
      end
   endrule

   rule bitChunk_v2;
      Bit#(6) value = 0;
      Bit#(16) coeff = 0;
      if (count == 0) begin
	 let currEncoding = encodingFIFO.first;
	 encodingFIFO.deq;
	 value = currEncoding.value;
	 maxCountReg <= currEncoding.size;
	 coeff = currEncoding.coeff;
	 outputFIFO.enq(currEncoding.value[0]);
	 count <= count + 1;
	 //$display("count:%d,value:%b,coeff:%d",count,value,coeff);
      end
      else if (count !=  maxCountReg) begin
	 //$display("max count:",maxCountReg);
	 if (count < 6) begin
	    value = valueReg >> 1;
	    coeff = coeffReg;
	    outputFIFO.enq(value[0]);
	    //$display("count:%d,value:%b,coeff:%d",count,value,coeff);
	 end
	 else begin
	    value = 0;
	    coeff = coeffReg >> 1;
	    outputFIFO.enq(coeffReg[0]);
	    //$display("count:%d,value:%b,coeff:%b",count,value,coeff);
	 end
	 count <= count + 1;
      end
      else begin
	 count <= 0;
      end
      valueReg <= value;
      coeffReg <= coeff;
   endrule
   */
   
   //conflicts with buffer_read, we make writes higher priority
   (* descending_urgency = "bitChunk_v3, buffer_read" *)
   rule bitChunk_v3 (can_write(bitBuffer,w_index)); //aggressive blocking for now
      Bit#(6) value = 0;
      Bit#(16) coeff = 0;
      Encoding curr = Encoding{size:0,value:0,coeff:0};
      //$display("coeff count:",coeff_count);
      //$display("w index:", w_index);
      //$display("valid?:", isValid(bitBuffer[w_index+curr.size-1]));
      if (coeff_count == 0) begin
	 currEncoding <= encodingFIFO.first;
	 curr = encodingFIFO.first[0];
	 if (!isValid(bitBuffer[w_index+curr.size-1])) encodingFIFO.deq;
      end
      else begin
	 curr = currEncoding[coeff_count];
      end
      //for (Integer j = 0; j < 63; j=j+1) begin
	//$display("w bit buffer:",fshow(bitBuffer[j]));
      //end
      //$display("w_index:",w_index);
      //$display("curr size:%d,curr value %b",curr.size, curr.value);
      for (Integer i = 0; i < 22; i=i+1) begin
	 if (fromInteger(i) < curr.size) begin
	    Maybe#(Bit#(1)) newBit = ?;
	    if (i < 6) begin
	       newBit = tagged Valid curr.value[i];
	    end
	    else begin
	       newBit = tagged Valid curr.coeff[i-6];
	    end
	    Bit#(6) newIndex = w_index + fromInteger(i);
	    bitBuffer[newIndex] <= newBit;
	 end
      end
      if (w_index + curr.size > 63) begin //*fromInteger(valueOf(p))) begin
	 w_index <= (w_index + curr.size) - 63;//*fromInteger(valueOf(p));
	 //$display("wrap:",w_index + 22 - 63);
      end
      else begin
	 w_index <= w_index + curr.size;
      end
      //$display("coeff_count",coeff_count);
      if (coeff_count == fromInteger(valueOf(TSub#(p,1)))) begin
	 coeff_count <= 0;
      end
      else begin
	 coeff_count <= coeff_count + 1;
      end

   endrule

   rule buffer_read (can_read(bitBuffer,r_index));//(isValid(bitBuffer[r_index]) && isValid(bitBuffer[r_index+3])); 
      Byte out = 0;
      //for (Integer j = 0; j < 63; j=j+1) begin
	 //$display("r bit buffer:",fshow(bitBuffer[j]));
      //end
      //$display("buffer read, r index:",r_index);
      for (Integer i = 0; i < 4; i=i+1) begin
	 out[i] = fromMaybe(?,bitBuffer[r_index + fromInteger(i)]);
	 bitBuffer[r_index+fromInteger(i)] <= tagged Invalid;
      end
      if (r_index + 3 > 63) begin //*fromInteger(valueOf(p))) begin
	 r_index <= (r_index + 4) - 63;//*fromInteger(valueOf(p));
      end
      else begin
	 r_index <= r_index + 4;
      end
      //$display("out",out);
      outputFIFO.enq(out);
   endrule
  
   interface Put request = toPut(inputFIFO);
   interface Get response = toGet(outputFIFO);

endmodule
