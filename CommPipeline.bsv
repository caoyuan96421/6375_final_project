import ClientServer::*;
import GetPut::*;

import Fifo::*;
import FIFO::*;
import Vector::*;

import SerializerBTP::*;
import SerializerPTW::*;
import DeserializerPTB::*;
import DeserializerWTP::*;
import Types::*;
import MemTypes::*;
import MemUtil::*;
import MemInit::*;
import CacheTypes::*;
import WideMemInit::*;
import CommTypes::*;
import Memory::*;

(* synthesize *)
module mkCommPipeline(CommIfc ifc);
   // interface FIFOs to real DDR3
   FIFO#(DDR3_Req)  ddr3ReqFifo  <- mkFIFO;
   FIFO#(DDR3_Resp) ddr3RespFifo <- mkFIFO;

   Reg#(Bool) mode <- mkReg(False);
   Reg#(Bool) started <- mkReg(False);
   Reg#(Bit#(24)) maxInAddr <- mkReg(0);
   Reg#(Bit#(24)) inAddr <-mkReg(0);
   Reg#(Bit#(24)) outAddr <- mkReg(0);
   
   BytesToPixel b2p <- mkSerializerBTP;
   PixelToMemWord p2w <- mkSerializerPTW;
   PixelToByte p2b <- mkDeserializerPTB;
   MemDataToPixel w2p <- mkDeserializerWTP;

   Reg#(Bit#(64)) cyc <- mkReg(0);
   rule incrCyc;
      cyc <= cyc + 1;
   endrule
   

   // This is probably not required
   rule deqTrash if (!started);
      ddr3RespFifo.deq;
   endrule

   // other rules
   rule b2p_to_p2w(started && !mode);
      let x <- b2p.response.get();
      p2w.request.put(x);
   endrule
/*
   rule drain (!mode && started);
      let x <- p2w.response.get;
   endrule
*/
   rule p2w_to_ddr3(started && !mode);
      let x <- p2w.response.get;
      Bit#(512) indata;
      indata = extend(inAddr/64);
      ddr3ReqFifo.enq(DDR3_Req{write: True, byteen: -1, address: inAddr, data: x.data});
      inAddr <= inAddr + 1;
      maxInAddr <= inAddr;
      $display("[%d]Word Input: %x, addr new: %x",cyc,x.data,inAddr);
   endrule

   rule ddr3_request(started && mode && (outAddr <= maxInAddr));
      ddr3ReqFifo.enq(DDR3_Req{write: False, byteen: -1, address: outAddr, data: ?});
      outAddr <= outAddr + 1; //change other location
      $display("[%d]Call to Mem: Addr= %d,out addr: %d",cyc,outAddr,outAddr);
   endrule

   rule ddr3_to_w2p(started && mode);
      let x = ddr3RespFifo.first;
      ddr3RespFifo.deq;
      w2p.request.put(x.data);
      $display("[%d]Word Output: %x",cyc,x.data);
   endrule

   rule w2p_to_p2b (started && mode); 
      let x <- w2p.response.get();
      p2b.request.put(x);
      $display("[%d]Pixel Output: %x",cyc,x);
   endrule
   
 
   method Action putByteInput(Byte x);
      b2p.request.put(x);
   endmethod
   
   method ActionValue#(Byte) getByteOutput() if (started);
      let x <- p2b.response.get;      
      $display("data out:", x);
      return x;
   endmethod

   method Action doInit (Bool x);
      mode <= x;
      started <= True;
   endmethod

   // interface for testbench to initialize DDR3
   //interface WideMemInitIfc memInit = ddr3InitIfc;
      // interface to real DDR3 controller
      interface DDR3_Client ddr3client = toGPClient( ddr3ReqFifo, ddr3RespFifo );

endmodule
