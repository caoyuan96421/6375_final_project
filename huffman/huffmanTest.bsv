import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import Encoder::*;
import SerializerbTB::*;
import DeserializerBTb::*;
import Decoder::*;
import CommTypes::*;

// Unit test for Serializing
(* synthesize *)
module mkHuffmanTest (Empty);

   Encode#(8) e <- mkEncoder();
   ByteToBit bb2b <- mkDeserializerBTb;
   Decode d <- mkDecoder;
   
   Reg#(Bool) passedEF <- mkReg(True);
   Reg#(Bit#(32)) feedEF <- mkReg(0);
   Reg#(Bit#(32)) checkEF <- mkReg(0);

   Reg#(Bool) passedDF <- mkReg(True);
   Reg#(Bit#(32)) feedDF <- mkReg(0);
   Reg#(Bit#(32)) checkDF <- mkReg(0);
	
   function Action dofeedEF(Vector#(8,Coeff) x);
      action
         e.request.put(x);
         feedEF <= feedEF+1;
      endaction
   endfunction
   
   function Action docheckEF(Coeff wnt);
      action
         let x <- d.response.get;
         if (x != wnt) begin
            $display("wnt: %x", wnt);
            $display("got: %x", x);
            passedEF <= False;
         end
	 else begin
	    $display("passed");
	 end
         checkEF <= checkEF+1;
      endaction
   endfunction

   rule e_to_b2bb;
      let x <- e.response.get();
      bb2b.request.put(x);
      //$display("bits to bytes:",fshow(x));
   endrule

   rule bb2b_to_d;
      let x <- bb2b.response.get();
      d.request.put(x);
      //$display("bits to decoder:", fshow(x));
   endrule
/*
   rule b2bb_to_bb2b;
      let x <- b2bb.response.get();
      bb2b.request.put(x);
      //$display("bytes to bytes:",fshow(x));
   endrule
 */
   Vector#(8,Coeff) ti1 = newVector;
   ti1[0] = 55;
   ti1[1] = 1;
   ti1[2] = -1;
   ti1[3] = 2;
   ti1[4] = -2;
   ti1[5] = 3;
   ti1[6] = -3;
   ti1[7] = -4;

   Vector#(8,Coeff) ti2 = newVector;
   ti2[0] = 0;
   ti2[1] = 0;
   ti2[2] = 0;
   ti2[3] = 0;
   ti2[4] = 0;
   ti2[5] = 0;
   ti2[6] = 0;
   ti2[7] = 0;
   rule f0 (feedEF == 0); dofeedEF(ti1); endrule
   rule f1 (feedEF == 1); dofeedEF(ti2); endrule
 
  rule c0 ((checkEF == 0)&&(feedEF == 2)); docheckEF(55); endrule
   rule c1 ((checkEF == 1)); docheckEF(1); endrule
   rule c2 ((checkEF == 2)); docheckEF(-1); endrule
   rule c3 ((checkEF == 3)); docheckEF(2); endrule
   rule c4 ((checkEF == 4)); docheckEF(-2); endrule
   rule c5 ((checkEF == 5)); docheckEF(3); endrule
   rule c6 ((checkEF == 6)); docheckEF(-3); endrule
   rule c7 ((checkEF == 7)); docheckEF(-4); endrule
   rule c8 ((checkEF == 8)); docheckEF(0); endrule
  
   rule finishEF (checkEF == 8);
      if (passedEF) begin
         $display("PASSED");
      end 
      else begin
	 $display("FAILED");
      end
      $finish();
   endrule

	


endmodule
