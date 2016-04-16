import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import DWT1D::*;
import DWTTypes::*;

typedef 8 N;
      
// Unit test for DWT module
(* synthesize *)
module mkDWT1DTest (Empty);

   DWT#(N) dwt1 <- mkDWT1D;
   
   Reg#(Bool) passed <- mkReg(True);
   Reg#(Bit#(32)) feed <- mkReg(0);
   Reg#(Bit#(32)) check <- mkReg(0);
	
   function Action dofeed(Vector#(N,Sample) x);
      action
         dwt1.request.put(toWSample(x));
	 //$display("Feed: ",feed);
         feed <= feed+1;
      endaction
   endfunction
   
   function Action docheck(Vector#(N, WSample) wnt);
      action
         let x <- dwt1.response.get;
	 	 $display("Check");
	 	 Bool correct = True;
	 	 Vector#(N, WSample) diff = replicate(0);
	 	 for(Integer i=0; i<valueOf(N); i=i+1)begin
	 	 	diff[i]=x[i]-wnt[i];
	 	 	if(diff[i] < fromReal(-1e-2) || diff[i] > fromReal(1e-2))
	 	 		correct = False;
	 	 end
         if (!correct) begin
            $display("wnt: ", fshow(wnt));
            $display("got: ", fshow(x));
            $display("diff: ", fshow(diff));
            passed <= False;
         end
         check <= check+1;
      endaction
   endfunction

   Vector#(N, Sample) in1 = replicate(0);
   in1[0]=1;
   in1[1]=2;
   in1[2]=3;
   in1[3]=4;
   in1[4]=5;
   in1[5]=6;
   in1[6]=7;
   in1[7]=8;
   
   Vector#(N, Sample) in2  = replicate(0);
   
   in2[0]=10;
   in2[1]=35;
   in2[2]=255;
   in2[3]=70;
   in2[4]=24;
   in2[5]=199;
   in2[6]=204;
   in2[7]=1;

   Vector#(N, Sample) in3  = replicate(0);
   
   in3[0]=0;
   in3[1]=1;
   in3[2]=1;
   in3[3]=1;
   in3[4]=0;
   in3[5]=0;
   in3[6]=0;
   in3[7]=0;
   
   Vector#(N, WSample) out1  = replicate(0);
   
   out1[0]=fromReal(1.8861);
   out1[1]=fromReal(4.3463);
   out1[2]=fromReal(6.9954);
   out1[3]=fromReal(9.9892);
   out1[4]=fromReal(0.1768);
   out1[5]=fromReal(0.0000);
   out1[6]=fromReal(-0.1291);
   out1[7]=fromReal(0.6117);
   
   Vector#(N, WSample) out2  = replicate(0);
   
   out2[0]=fromReal(33.6433);
   out2[1]=fromReal(33.5332);
   out2[2]=fromReal(28.7867);
   out2[3]=fromReal(-61.8174);
   out2[4]=fromReal(21.0462);
   out2[5]=fromReal(43.7624);
   out2[6]=fromReal(-39.5466);
   out2[7]=fromReal(52.0065);
   
   Vector#(N, WSample) out3  = replicate(0);
   
   out3[0]=fromReal(0.4859);
   out3[1]=fromReal(1.6215);
   out3[2]=fromReal(0.2429);
   out3[3]=fromReal(0.0140);
   out3[4]=fromReal(0.3536);
   out3[5]=fromReal(0.3297);
   out3[6]=fromReal(0.0238);
   out3[7]=fromReal(0);
   
   rule f0 (feed == 0); dofeed(in1); endrule
   rule f1 (feed == 1); dofeed(in2); endrule
   rule f2 (feed == 2); dofeed(in3); endrule
   
   rule c0 (check == 0); docheck(out1); endrule
   rule c1 (check == 1); docheck(out2); endrule
   rule c2 (check == 2); docheck(out3); endrule

   rule finish (check == 3);
      if (passed) begin
         $display("PASSED");
      end 
      else begin
	 $display("FAILED");
      end
      $finish();
   endrule

endmodule
