import ClientServer::*;
import GetPut::*;
import Fifo::*;
import Vector::*;
import FixedPoint::*;

import CommTypes::*;

typedef struct {
        Bit#(6) size;
	Bit#(6) value;
        Bit#(16) coeff;
        } Encoding  deriving (Bits,Eq);

typedef Server#(
		Coeff,
		Bit#(1)
		)Encode;

(* synthesize *)
module mkEncoder(Encode ifc);
   Fifo#(2,Coeff) inputFIFO <- mkCFFifo;
   Fifo#(44,Bit#(1)) outputFIFO <- mkCFFifo; //scaled so that 2 coeffs = 44 bits
   Reg#(Bit#(6)) count <- mkReg(0);
   Reg#(Bit#(6)) maxCountReg <- mkReg(0);
   Reg#(Bit#(6)) valueReg <- mkReg(0);
   Reg#(Bit#(16)) coeffReg <- mkReg(0);
   Fifo#(2,Encoding) encodingFIFO <- mkCFFifo;

   rule map2encoding;
      let inCoeff = fxptGetInt(inputFIFO.first);
      //$display("from the input fifo:",inCoeff);
      Bit#(16) inCoeffB = pack(inCoeff);
      //$display("as bits:",inCoeff);
      inputFIFO.deq;
      //values are backward here so read forward at end.
      //coeffs should be fipped on the decoder side.
      case (inCoeff)
	 0: encodingFIFO.enq(Encoding{size:2,value:6'b000001, coeff: ?});       
	 1: encodingFIFO.enq(Encoding{size:4,value:6'b000011, coeff: ?});
	 -1:encodingFIFO.enq(Encoding{size:4,value:6'b001011, coeff: ?});
	 2: encodingFIFO.enq(Encoding{size:5,value:6'b000111, coeff: ?});
	 -2:encodingFIFO.enq(Encoding{size:5,value:6'b010111, coeff: ?});
	 3: encodingFIFO.enq(Encoding{size:6,value:6'b001111, coeff: ?});
	 -3:encodingFIFO.enq(Encoding{size:6,value:6'b101111, coeff: ?});
	 -4:encodingFIFO.enq(Encoding{size:6,value:6'b011111, coeff: ?});
	 default:encodingFIFO.enq(Encoding{size:22,value:6'b111111, coeff:inCoeffB});
      endcase
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
*/
   rule load_bitChunk_v2;
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
   
   interface Put request;
      method Action put (Coeff x);
	 inputFIFO.enq(x);
      endmethod
   endinterface
   interface Get response = toGet(outputFIFO);

endmodule
