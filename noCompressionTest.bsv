import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import SerializerBTP::*;
import SerializerPTW::*;
import DeserializerPTB::*;
import DeserializerWTP::*;
import CommTypes::*;

// Unit test for Serializing
(* synthesize *)
module mkNoCompressionTest (Empty);

   BytesToPixel b2p <- mkSerializerBTP;
   PixelToMemWord p2w <- mkSerializerPTW;
   PixelToByte p2b <- mkDeserializerPTB;
   MemDataToPixel w2p <- mkDeserializerWTP;
   
   Reg#(Bool) passed <- mkReg(True);
   Reg#(Bit#(32)) feed <- mkReg(0);
   Reg#(Bit#(32)) check <- mkReg(0);
	
   function Action dofeed(Byte x);
      action
         b2p.request.put(x);
	 //$display("Feed: ",feed);
         feed <= feed+1;
      endaction
   endfunction
   
   function Action docheck(Byte wnt);
      action
         let x <- p2b.response.get;
         if (x != wnt) begin
            $display("wnt: %x", wnt);
            $display("got: %x", x);
            passed <= False;
         end
         check <= check+1;
      endaction
   endfunction

   rule b2p_to_p2w;
      let x <- b2p.response.get();
      p2w.request.put(x);
   endrule

   rule w2p_to_p2b;
      let x <- w2p.response.get();
      p2b.request.put(x);
   endrule

   rule p2w_to_w2p;
      let x <- p2w.response.get();
      w2p.request.put(x.data);
   endrule

   rule f0 (feed == 0); dofeed(0); endrule
   rule f1 (feed == 1); dofeed(1); endrule
   rule f2 (feed == 2); dofeed(2); endrule
   rule f3 (feed == 3); dofeed(3); endrule
   rule f4 (feed == 4); dofeed(4); endrule
   rule f5 (feed == 5); dofeed(5); endrule
   rule f6 (feed == 6); dofeed(6); endrule
   rule f7 (feed == 7); dofeed(7); endrule
   rule f8 (feed == 8); dofeed(8); endrule
   rule f9 (feed == 9); dofeed(9); endrule
   rule f10 (feed == 10); dofeed(10); endrule
   rule f11 (feed == 11); dofeed(11); endrule
   rule f12 (feed == 12); dofeed(12); endrule
   rule f13 (feed == 13); dofeed(13); endrule
   rule f14 (feed == 14); dofeed(14); endrule
   rule f15 (feed == 15); dofeed(15); endrule
   rule f16 (feed == 16); dofeed(1); endrule
   rule f17 (feed == 17); dofeed(2); endrule
   rule f18 (feed == 18); dofeed(3); endrule
   rule f19 (feed == 19); dofeed(4); endrule
   rule f20 (feed == 20); dofeed(5); endrule
   rule f21 (feed == 21); dofeed(6); endrule
   rule f22 (feed == 22); dofeed(7); endrule
   rule f23 (feed == 23); dofeed(8); endrule
   rule f24 (feed == 24); dofeed(9); endrule
   rule f25 (feed == 25); dofeed(10); endrule
   rule f26 (feed == 26); dofeed(11); endrule
   rule f27 (feed == 27); dofeed(12); endrule
   rule f28 (feed == 28); dofeed(13); endrule
   rule f29 (feed == 29); dofeed(14); endrule
   rule f30 (feed == 30); dofeed(15); endrule
   rule f31 (feed == 31); dofeed(1); endrule
   rule f32 (feed == 32); dofeed(2); endrule
   rule f33 (feed == 33); dofeed(3); endrule
   rule f34 (feed == 34); dofeed(4); endrule
   rule f35 (feed == 35); dofeed(5); endrule
   rule f36 (feed == 36); dofeed(6); endrule
   rule f37 (feed == 37); dofeed(7); endrule
   rule f38 (feed == 38); dofeed(8); endrule
   rule f39 (feed == 39); dofeed(9); endrule
   rule f40 (feed == 40); dofeed(10); endrule
   rule f41 (feed == 41); dofeed(11); endrule
   rule f42 (feed == 42); dofeed(12); endrule
   rule f43 (feed == 43); dofeed(13); endrule
   rule f44 (feed == 44); dofeed(14); endrule
   rule f45 (feed == 45); dofeed(15); endrule
   rule f46 (feed == 46); dofeed(1); endrule
   rule f47 (feed == 47); dofeed(2); endrule
   rule f48 (feed == 48); dofeed(3); endrule
   rule f49 (feed == 49); dofeed(4); endrule
   rule f50 (feed == 50); dofeed(5); endrule
   rule f51 (feed == 51); dofeed(6); endrule
   rule f52 (feed == 52); dofeed(7); endrule
   rule f53 (feed == 53); dofeed(8); endrule
   rule f54 (feed == 54); dofeed(9); endrule
   rule f55 (feed == 55); dofeed(10); endrule
   rule f56 (feed == 56); dofeed(11); endrule
   rule f57 (feed == 57); dofeed(12); endrule
   rule f58 (feed == 58); dofeed(13); endrule
   rule f59 (feed == 59); dofeed(14); endrule
   rule f60 (feed == 60); dofeed(15); endrule
   rule f61 (feed == 61); dofeed(1); endrule
   rule f62 (feed == 62); dofeed(2); endrule
   rule f63 (feed == 63); dofeed(3); endrule
   rule f64 (feed == 64); dofeed(4); endrule
   rule f65 (feed == 65); dofeed(5); endrule
   rule f66 (feed == 66); dofeed(6); endrule
   rule f67 (feed == 67); dofeed(7); endrule
   rule f68 (feed == 68); dofeed(8); endrule
   rule f69 (feed == 69); dofeed(9); endrule
   rule f70 (feed == 70); dofeed(10); endrule
   rule f71 (feed == 71); dofeed(11); endrule
   rule f72 (feed == 72); dofeed(12); endrule
   rule f73 (feed == 73); dofeed(13); endrule
   rule f74 (feed == 74); dofeed(14); endrule
   rule f75 (feed == 75); dofeed(15); endrule
   rule f76 (feed == 76); dofeed(1); endrule
   rule f77 (feed == 77); dofeed(2); endrule
   rule f78 (feed == 78); dofeed(3); endrule
   rule f79 (feed == 79); dofeed(4); endrule
   rule f80 (feed == 80); dofeed(5); endrule
   rule f81 (feed == 81); dofeed(6); endrule
   rule f82 (feed == 82); dofeed(7); endrule
   rule f83 (feed == 83); dofeed(8); endrule
   rule f84 (feed == 84); dofeed(9); endrule
   rule f85 (feed == 85); dofeed(10); endrule
   rule f86 (feed == 86); dofeed(11); endrule
   rule f87 (feed == 87); dofeed(12); endrule
   rule f88 (feed == 88); dofeed(13); endrule
   rule f89 (feed == 89); dofeed(14); endrule
   rule f90 (feed == 90); dofeed(15); endrule
   rule f91 (feed == 91); dofeed(1); endrule
   rule f92 (feed == 92); dofeed(2); endrule
   rule f93 (feed == 93); dofeed(3); endrule
   rule f94 (feed == 94); dofeed(4); endrule
   rule f95 (feed == 95); dofeed(5); endrule
   rule f96 (feed == 96); dofeed(6); endrule
    
   rule c0 ((check == 0)&&(feed == 97)); docheck(0); endrule
   rule c1 (check == 1); docheck(1); endrule
   rule c2 (check == 2); docheck(2); endrule
   rule c3 (check == 3); docheck(3); endrule
   rule c4 (check == 4); docheck(4); endrule
   rule c5 (check == 5); docheck(5); endrule
   rule c6 (check == 6); docheck(6); endrule
   rule c7 (check == 7); docheck(7); endrule
   rule c8 (check == 8); docheck(8); endrule
   rule c9 (check == 9); docheck(9); endrule
   rule c10 (check == 10); docheck(10); endrule
   rule c11 (check == 11); docheck(11); endrule
   rule c12 (check == 12); docheck(12); endrule
   rule c13 (check == 13); docheck(13); endrule
   rule c14 (check == 14); docheck(14); endrule
   rule c15 (check == 15); docheck(15); endrule
   rule c16 (check == 16); docheck(1); endrule
   rule c17 (check == 17); docheck(2); endrule
   rule c18 (check == 18); docheck(3); endrule
   rule c19 (check == 19); docheck(4); endrule
   rule c20 (check == 20); docheck(5); endrule
   rule c21 (check == 21); docheck(6); endrule
   rule c22 (check == 22); docheck(7); endrule
   rule c23 (check == 23); docheck(8); endrule
   rule c24 (check == 24); docheck(9); endrule
   rule c25 (check == 25); docheck(10); endrule
   rule c26 (check == 26); docheck(11); endrule
   rule c27 (check == 27); docheck(12); endrule
   rule c28 (check == 28); docheck(13); endrule
   rule c29 (check == 29); docheck(14); endrule
   rule c30 (check == 30); docheck(15); endrule
   rule c31 (check == 31); docheck(1); endrule
   rule c32 (check == 32); docheck(2); endrule
   rule c33 (check == 33); docheck(3); endrule
   rule c34 (check == 34); docheck(4); endrule
   rule c35 (check == 35); docheck(5); endrule
   rule c36 (check == 36); docheck(6); endrule
   rule c37 (check == 37); docheck(7); endrule
   rule c38 (check == 38); docheck(8); endrule
   rule c39 (check == 39); docheck(9); endrule
   rule c40 (check == 40); docheck(10); endrule
   rule c41 (check == 41); docheck(11); endrule
   rule c42 (check == 42); docheck(12); endrule
   rule c43 (check == 43); docheck(13); endrule
   rule c44 (check == 44); docheck(14); endrule
   rule c45 (check == 45); docheck(15); endrule
   rule c46 (check == 46); docheck(1); endrule
   rule c47 (check == 47); docheck(2); endrule
   rule c48 (check == 48); docheck(3); endrule
   rule c49 (check == 49); docheck(4); endrule
   rule c50 (check == 50); docheck(5); endrule
   rule c51 (check == 51); docheck(6); endrule
   rule c52 (check == 52); docheck(7); endrule
   rule c53 (check == 53); docheck(8); endrule
   rule c54 (check == 54); docheck(9); endrule
   rule c55 (check == 55); docheck(10); endrule
   rule c56 (check == 56); docheck(11); endrule
   rule c57 (check == 57); docheck(12); endrule
   rule c58 (check == 58); docheck(13); endrule
   rule c59 (check == 59); docheck(14); endrule
   rule c60 (check == 60); docheck(15); endrule
   rule c61 (check == 61); docheck(1); endrule
   rule c62 (check == 62); docheck(2); endrule
   rule c63 (check == 63); docheck(3); endrule
   rule c64 (check == 64); docheck(4); endrule
   rule c65 (check == 65); docheck(5); endrule
   rule c66 (check == 66); docheck(6); endrule
   rule c67 (check == 67); docheck(7); endrule
   rule c68 (check == 68); docheck(8); endrule
   rule c69 (check == 69); docheck(9); endrule
   rule c70 (check == 70); docheck(10); endrule
   rule c71 (check == 71); docheck(11); endrule
   rule c72 (check == 72); docheck(12); endrule
   rule c73 (check == 73); docheck(13); endrule
   rule c74 (check == 74); docheck(14); endrule
   rule c75 (check == 75); docheck(15); endrule
   rule c76 (check == 76); docheck(1); endrule
   rule c77 (check == 77); docheck(2); endrule
   rule c78 (check == 78); docheck(3); endrule
   rule c79 (check == 79); docheck(4); endrule
   rule c80 (check == 80); docheck(5); endrule
   rule c81 (check == 81); docheck(6); endrule
   rule c82 (check == 82); docheck(7); endrule
   rule c83 (check == 83); docheck(8); endrule
   rule c84 (check == 84); docheck(9); endrule
   rule c85 (check == 85); docheck(10); endrule
   rule c86 (check == 86); docheck(11); endrule
   rule c87 (check == 87); docheck(12); endrule
   rule c88 (check == 88); docheck(13); endrule
   rule c89 (check == 89); docheck(14); endrule
   rule c90 (check == 90); docheck(15); endrule
   rule c91 (check == 91); docheck(1); endrule
   rule c92 (check == 92); docheck(2); endrule
   rule c93 (check == 93); docheck(3); endrule
   rule c94 (check == 94); docheck(4); endrule
   rule c95 (check == 95); docheck(5); endrule
   rule c96 (check == 96); docheck(6); endrule

   rule finish (check == 96);
      if (passed) begin
         $display("PASSED");
      end 
      else begin
	 $display("FAILED");
      end
      $finish();
   endrule

endmodule
