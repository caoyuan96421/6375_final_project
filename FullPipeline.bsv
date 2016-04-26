import ClientServer::*;
import GetPut::*;

import Fifo::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;
import Types::*;
import MemTypes::*;
import MemUtil::*;
import Memory::*;
import FShow::*;
import DWT2D::*;
import DWT2DML::*;
import DWTTypes::*;
import Encoder_v2::*;
import Decoder_v2::*;
import HuffmanTable::*;
import CommTypes::*;

typedef 256 N;
typedef 256 M;
//typedef 8 N;
//typedef 8 M;
typedef 2 B;
typedef 1 T;
typedef 3 L;

(* synthesize *)
module mkFullPipeline(CommIfc ifc);
   // interface FIFOs to real DDR3
   FIFO#(DDR3_Req)  ddr3ReqFifo  <- mkFIFO;
   FIFO#(DDR3_Resp) ddr3RespFifo <- mkFIFO;

   Reg#(Bool) mode <- mkReg(False);
   Reg#(Bool) started <- mkReg(False);
   Reg#(Bit#(24)) maxInAddr <- mkReg(0);
   Reg#(Bit#(24)) inAddr <-mkReg(0);
   Reg#(Bit#(24)) outAddr <- mkReg(0);

   DWT2DMLI#(N,M,B,L) dwt2d <- mkDWT2DMLI();
   IDWT2DMLI#(N,M,B,L) idwt2d <- mkIDWT2DMLI();
   Encoder#(WC, 4) encoder <- mkEncoder(huffmanTable1);
   Decoder#(4, WC) decoder <- mkDecoder(huffmanTable1);
   FIFO#(Vector#(B, Coeff)) efifo <- mkFIFO;
   Vector#(B, Reg#(Coeff)) dbuf <- replicateM(mkRegU);

   Reg#(Bool) m_inited <- mkReg(False);
   Reg#(File) m_in <- mkRegU();
   Reg#(File) m_out <- mkRegU();
   Reg#(Bool) m_doneread <- mkReg(False);
   Reg#(Bit#(32)) m_sample_in <- mkReg(0);
   Reg#(Bit#(32)) m_line_in <- mkReg(0);
   Reg#(Bit#(32)) m_line_out <- mkReg(0);
   Reg#(Bit#(4)) t <- mkReg(0);
   Reg#(Bit#(4)) ecount <- mkReg(0);
   Reg#(Bit#(4)) dcount <- mkReg(0);

   Reg#(Bit#(64)) cyc <- mkReg(0);
   rule incrCyc;
      cyc <= cyc + 1;
   endrule
   
   // This is probably not required
   rule deqTrash if (!started);
      ddr3RespFifo.deq;
   endrule
/*
   rule test(!mode);
      let x <- decoder.response.get;
      Int#(WC) disp_int = unpack(x);
      $display("decoder out!:",disp_int);
      encoder.request.put(x);
   endrule
*/      
/*
   rule test(!mode);
      decoder.request.put(10);
   endrule
*/
   // other rules
   rule collectdecoder(started && !mode);
      //$display("collect decoder");
      let x <- decoder.response.get;
      if(dcount == fromInteger(valueOf(B))-1)begin
	 Vector#(B, Coeff) v = newVector;
	 for(Integer i=0;i<valueOf(B)-1;i=i+1)
	    v[i] = dbuf[i];
	 v[valueOf(B)-1] = unpack(x);
	 $display("[%t]to idwt2d:",$time,fshow(v));
	 idwt2d.request.put(v);
	 dcount <= 0;
      end
      else begin
	 dbuf[dcount] <= unpack(x);
	 dcount <= dcount + 1;
      end
   endrule
/*
   rule idwt_to_dwt(started && !mode);
      let x <- idwt2d.response.get();
      $display("[%t]to dwt2d (px values):",$time,fshow(x));
      dwt2d.request.put(x);
   endrule
*/      

   rule idwt_to_ddr3(started && !mode);
      let x <- idwt2d.response.get();
      $display("[%t]got idwt response:",$time,fshow(x));
      Bit#(512) indata = 0;
      Integer sample_size = valueOf(SizeOf#(Sample));
      for (Integer i = 0; i < valueOf(B); i=i+1) begin
	 indata[(i+1)*sample_size-1:i*sample_size] = pack(x[i]);
      end
      ddr3ReqFifo.enq(DDR3_Req{write: True, byteen: -1, address: inAddr, data: indata});
      inAddr <= inAddr + 1;
      maxInAddr <= inAddr;
      $display("[%t]Word Input: %x, addr new: %x,from idwt2:",$time,indata,inAddr,x);
   endrule

   rule ddr3_request(started && mode && (outAddr <= maxInAddr));
      ddr3ReqFifo.enq(DDR3_Req{write: False, byteen: -1, address: outAddr, data: ?});
      outAddr <= outAddr + 1; //change other location
      $display("[%t]Call to Mem: Addr= %d,out addr: %d",$time,outAddr,outAddr);
   endrule

   rule ddr3_to_dwt(started && mode);
      let x = ddr3RespFifo.first;
      ddr3RespFifo.deq;
      Integer sample_size = valueOf(SizeOf#(Sample));
      Vector#(B,Sample) v = newVector;
      for (Integer i = 0; i < valueOf(B); i=i+1) begin
	 v[i] = unpack(x.data[(i+1)*sample_size-1:i*sample_size]);
      end
      dwt2d.request.put(v);
      $display("[%t]Word Output: %x",$time,x.data);
   endrule

   rule dwt2huffman(started && mode);
      let x <- dwt2d.response.get();
      efifo.enq(x);
      $display("[%t]to Huffman:",$time, fshow(x));
   endrule

   rule feedencoder (started && mode); 
      let x = efifo.first;
      $display("[%t]to encoder:",$time,x);
      encoder.request.put(pack(x[ecount]));
      if(ecount == fromInteger(valueOf(B))-1)begin
	 ecount <= 0;
	 efifo.deq;
      end
      else begin
	 ecount <= ecount + 1;
      end
   endrule   
 
   method Action putByteInput(Byte x);
      //$display("data in:", x);
      decoder.request.put(x);
      //decoder.request.put(10);
   endmethod
   
   method ActionValue#(Byte) getByteOutput();
      let x <- encoder.response.get();      
      //$display("data out:", x);
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
