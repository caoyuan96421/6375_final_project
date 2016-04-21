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
import huffmanLoopBack::*;

// Unit test for Serializing
(* synthesize *)
module mkHuffmanTest (Empty);

   //Encode#(8) e <- mkEncoder();
   //Decode#(8) d <- mkDecoder;
   HuffmanLoopBack#(8) lb <- mkHuffmanLoopBack();
   
   Reg#(Bool) passedEF <- mkReg(True);
   Reg#(Bit#(32)) feedEF <- mkReg(0);
   Reg#(Bit#(32)) checkEF <- mkReg(0);

   Reg#(Bool) passedDF <- mkReg(True);
   Reg#(Bit#(32)) feedDF <- mkReg(0);
   Reg#(Bit#(32)) checkDF <- mkReg(0);
	
   function Action dofeedEF(Vector#(8,Coeff) x);
      action
         //e.request.put(x);
	 lb.request.put(x);
         feedEF <= feedEF+1;
      endaction
   endfunction

   function Action docheckEF(Vector#(8,Coeff) wnt);
      action
	 let x <- lb.response.get;
	 $display("wnt: %x", wnt);
         $display("got: %x", x);
	 $display("check:",checkEF);
	 //let x <- d.response.get;
	 if (x != wnt) begin
            //$display("wnt: %x", wnt);
            //$display("got: %x", x);
	    $display("failed");
            passedEF <= False;
         end
	 else begin
	    $display("passed");
	 end
         checkEF <= checkEF+1;
      endaction
   endfunction
	 
/*
   rule e_to_d;
      let x <- e.response.get();
      d.request.put(x);
      $display("encode to bytes:",fshow(x));
   endrule
  */
   Vector#(8,Coeff) ti1 = replicate (0);
   ti1[0] = 55;
   ti1[1] = 1;
   ti1[2] = -1;
   ti1[3] = 2;
   ti1[4] = -2;
   ti1[5] = 3;
   ti1[6] = -3;
   ti1[7] = -4;

   Vector#(8,Coeff) to1 = replicate (0);
   to1[0] = 55;
   to1[1] = 1;
   to1[2] = -1;
   to1[3] = 2;
   to1[4] = -2;
   to1[5] = 3;
   to1[6] = -3;
   to1[7] = -4;

   Vector#(8,Coeff) ti2 = replicate (0);
   ti2[0] = 0;
   ti2[1] = 0;
   ti2[2] = 0;
   ti2[3] = 0;
   ti2[4] = 0;
   ti2[5] = 0;
   ti2[6] = 0;
   ti2[7] = 0;

   Vector#(8,Coeff) to2 = replicate (0);
   to2[0] = 0;
   to2[1] = 0;
   to2[2] = 0;
   to2[3] = 0;
   to2[4] = 0;
   to2[5] = 0;
   to2[6] = 0;
   to2[7] = 0;

   Vector#(8,Coeff) ti3 = replicate (0);
   ti3[0] = 0;
   ti3[1] = 3;
   ti3[2] = -4;
   ti3[3] = 2;
   ti3[4] = -1;
   ti3[5] = -1;
   ti3[6] = 0;
   ti3[7] = 47;

   Vector#(8,Coeff) to3 = replicate (0);
   to3[0] = 0;
   to3[1] = 3;
   to3[2] = -4;
   to3[3] = 2;
   to3[4] = -1;
   to3[5] = -1;
   to3[6] = 0;
   to3[7] = 47;

   
   rule f0 (feedEF == 0); dofeedEF(ti3); endrule
   rule f1 (feedEF == 1); dofeedEF(ti1); endrule
   rule f2 (feedEF == 2); dofeedEF(ti3); endrule
   rule f3 (feedEF == 3); dofeedEF(ti2); endrule
   rule f4 (feedEF == 4); dofeedEF(ti2); endrule
   rule f5 (feedEF == 5); dofeedEF(ti2); endrule
   rule c0 ((checkEF == 0)&&(feedEF == 6)); docheckEF(to3); endrule
   rule c1 (checkEF == 1); docheckEF(to1); endrule
   rule c2 (checkEF == 2); docheckEF(to3); endrule
   rule c3 (checkEF == 3); docheckEF(to2); endrule
   rule c4 (checkEF == 4); docheckEF(to2); endrule
   //rule c5 (checkEF == 5); docheckEF(to2); endrule
   
   
 /*
  rule c0 ((checkEF == 0)&&(feedEF == 2)); docheckEF(55); endrule
   rule c1 ((checkEF == 1)); docheckEF(1); endrule
   rule c2 ((checkEF == 2)); docheckEF(-1); endrule
   rule c3 ((checkEF == 3)); docheckEF(2); endrule
   rule c4 ((checkEF == 4)); docheckEF(-2); endrule
   rule c5 ((checkEF == 5)); docheckEF(3); endrule
   rule c6 ((checkEF == 6)); docheckEF(-3); endrule
   rule c7 ((checkEF == 7)); docheckEF(-4); endrule
   rule c8 ((checkEF == 8)); docheckEF(0); endrule
  */
   rule finishEF (checkEF == 5);
      if (passedEF) begin
         $display("PASSED");
      end 
      else begin
	 $display("FAILED");
      end
      $finish();
   endrule

	


endmodule
