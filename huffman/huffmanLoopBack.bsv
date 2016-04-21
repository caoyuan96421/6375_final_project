import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import Encoder::*;
import FIFO::*;
import DeserializerBTb::*;
import Decoder::*;
import CommTypes::*;

typedef Server#(
		Vector#(p,Coeff),
		Vector#(p,Coeff)
		)HuffmanLoopBack#(numeric type p);

module mkHuffmanLoopBack (HuffmanLoopBack#(p) ifc);
   FIFO#(Vector#(p,Coeff)) inFIFO <- mkFIFO;
   FIFO#(Vector#(p,Coeff)) outFIFO <- mkFIFO;
   Encode#(p) e <- mkEncoder();
   ByteToBit bb2b <- mkDeserializerBTb;
   Decode d <- mkDecoder;
   Reg#(Bit#(TLog#(p))) count <- mkReg(0);
   Vector#(p,Reg#(Coeff)) storeVect <- replicateM(mkReg(0));

   rule in_to_e;
      let x = inFIFO.first;
      inFIFO.deq;
      e.request.put(x);
   endrule

   rule e_to_b2bb;
      let x <- e.response.get();
      bb2b.request.put(x);
      //display("encode to bytes:",fshow(x));
   endrule

   rule bb2b_to_d;
      let x <- bb2b.response.get();
      d.request.put(x);
   endrule

   rule d_to_vect;
      let x <- d.response.get();
      Vector#(p,Coeff) outVect = replicate(0);
      //$display("count:",count);
      //$display("coeff:",x);
      if (count == fromInteger(valueOf(TSub#(p,1)))) begin
	 for (Integer i = 0; i < valueOf(TSub#(p,1)); i=i+1) begin
	    outVect[i] = storeVect[i];
	 end
	 outVect[fromInteger(valueOf(TSub#(p,1)))] = x;
	 outFIFO.enq(outVect);
	 count <= 0;
      end
      else begin
	 storeVect[count] <= x;
	 count <= count + 1;
      end
   endrule

   interface Put request = toPut(inFIFO);
   interface Get response = toGet(outFIFO);

endmodule
