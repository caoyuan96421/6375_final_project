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
import Ehr::*;

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
	
	Integer ppi = valueOf(DDR3DataSize) / (valueOf(B) * valueOf(SizeOf#(Sample))); // packet per request to DRAM
	Integer psize = valueOf(B) * valueOf(SizeOf#(Sample)); // packet bit size
	
	Vector#(TDiv#(DDR3DataSize,SizeOf#(Vector#(B, Sample))), Reg#(Bit#(SizeOf#(Vector#(B, Sample))))) dpacket <- replicateM(mkReg(0));

	Reg#(Bit#(4)) t <- mkReg(0);
	Reg#(Bit#(4)) ecount <- mkReg(0);
	Reg#(Bit#(4)) dcount <- mkReg(0);
	Reg#(Bit#(16)) pcount <- mkReg(0);
	Reg#(Bit#(16)) qcount <- mkReg(0);

	Ehr#(2,Bit#(64)) cyc <- mkEhr(0);
	FIFO#(Bit#(64)) ocfifo <- mkFIFO;
	
	Ehr#(2,Bit#(32)) count_decompress <- mkEhr(0);
	
	(* fire_when_enabled *)
	(* no_implicit_conditions *)
	rule incrCyc;
		cyc[0] <= cyc[0] + 1;
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

	rule idwt_to_ddr3(started && !mode);
		let x <- idwt2d.response.get();
		$display("[%t]got idwt response [%d]:",$time,fshow(x), pcount);
		
		let indata = readVReg(dpacket);
		indata[pcount] = pack(x);
		dpacket[pcount] <= pack(x);
		
		if(pcount == fromInteger(ppi - 1))begin
			ddr3ReqFifo.enq(DDR3_Req{write: True, byteen: '1, address: inAddr, data: pack(indata)});
			inAddr <= inAddr + 1;
			maxInAddr <= inAddr;
			$display("[%t]Word Input: %x, addr new: %x,from idwt2:",$time,pack(indata),inAddr,x);
			
			pcount <= 0;
		end
		else begin
			pcount <= pcount + 1;
		end
		
		
		Bit#(32) newcount = count_decompress[0] + fromInteger(valueOf(B));
		if(newcount == fromInteger(valueOf(N)*valueOf(M)))begin
			// Decompression finished! Switch mode
			$display("[%t]Switch mode. Cycle=%d", $time, cyc[0]);
			mode <= True;
			ocfifo.enq(cyc[0]);
		end
		count_decompress[0] <= newcount;
	endrule

	rule ddr3_request(started && mode && (outAddr <= maxInAddr));
		ddr3ReqFifo.enq(DDR3_Req{write: False, byteen: '1, address: outAddr, data: ?});
		outAddr <= outAddr + 1; //change other location
		$display("[%t]Call to Mem: Addr= %d,out addr: %d",$time,outAddr,outAddr);
	endrule

	rule ddr3_to_dwt(started && mode);
		Vector#(TDiv#(DDR3DataSize,SizeOf#(Vector#(B, Sample))), Bit#(SizeOf#(Vector#(B, Sample)))) y = unpack(ddr3RespFifo.first.data);
		Bit#(SizeOf#(Vector#(B, Sample))) x = y[qcount];
		if(qcount == fromInteger(ppi - 1))begin
			// Finished this block
			ddr3RespFifo.deq;
			qcount <= 0;
		end
		else begin
			qcount <= qcount + 1;
		end
		Vector#(B,Sample) v = unpack(x);
		dwt2d.request.put(v);
		$display("[%t]Word Output [%d]: %x",$time, qcount, x);
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
 

	interface Server data;
		interface Put request;
			method Action put(Byte x) if (started) = decoder.request.put(x);
		endinterface
		interface Get response;
			method ActionValue#(Byte) get() if(started) = encoder.response.get;
		endinterface
	endinterface

	interface Put start;
		method Action put (Bit#(1) x);
			started <= True;
			cyc[1] <= 0;
			count_decompress[1] <= 0;
			mode <= False;
		endmethod
	endinterface
	
	interface Get count = toGet(ocfifo);

	interface DDR3_Client ddr3client = toGPClient( ddr3ReqFifo, ddr3RespFifo );
endmodule
