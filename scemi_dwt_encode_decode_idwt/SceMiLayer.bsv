import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;
import ResetXactor::*;
import Xilinx::*;
import Vector::*;

import CommTypes::*;
import DWT2DML::*;

import Encoder_v2::*;
import Decoder_v2::*;
import HuffmanTable::*;

typedef 1024 N; // Maximum line size
typedef 1024 M; // Maximum line number
typedef 2 P; // Block size
typedef 3 L; // Transformation level
typedef 4 B; // Byte bitwidth
typedef Vector#(P, Sample) DWT_Line;

typedef Server#(
	Vector#(P, Sample),
	Vector#(P, Sample)
)DutInterface;

(* synthesize *)
module mkDWT2DMLIStatic(DWT2DMLI#(N,M,P,L));
	DWT2DMLI#(N,M,P,L) dwt2d <- mkDWT2DMLI;
	return dwt2d;
endmodule

(* synthesize *)
module mkIDWT2DMLIStatic(IDWT2DMLI#(N,M,P,L));
	IDWT2DMLI#(N,M,P,L) idwt2d <- mkIDWT2DMLI;
	return idwt2d;
endmodule

(* synthesize *)
module mkEncoderStatic(Encoder#(WC, B));
	Encoder#(WC, B) e <- mkEncoder(huffmanTable1);
	return e;
endmodule

(* synthesize *)
module mkDecoderStatic(Decoder#(B, WC));
	Decoder#(B, WC) d <- mkDecoder(huffmanTable1);
	return d;
endmodule

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT2DMLI#(N,M,P,L) dwt2d <- mkDWT2DMLIStatic;
	IDWT2DMLI#(N,M,P,L) idwt2d <- mkIDWT2DMLIStatic;
	Encoder#(WC, B) encoder <- mkEncoderStatic;
	Decoder#(B, WC) decoder <- mkDecoderStatic;
	
	FIFO#(Vector#(P, Coeff)) efifo <- mkFIFO;
	Vector#(P, Reg#(Coeff)) dbuf <- replicateM(mkRegU);
	Reg#(Bit#(4)) ecount <- mkReg(0);
	Reg#(Bit#(4)) dcount <- mkReg(0);
		
	rule d2e;
		let x <- dwt2d.response.get;
		efifo.enq(x);
	endrule
	
	(* fire_when_enabled *)
	rule feedencoder;
		let x = efifo.first;
		encoder.request.put(pack(x[ecount]));
		if(ecount == fromInteger(valueOf(P))-1)begin
			ecount <= 0;
			efifo.deq;
		end
		else begin
			ecount <= ecount + 1;
		end
	endrule
	
	rule e2d;
		let x <- encoder.response.get;
		decoder.request.put(x);
	endrule
	
	(* fire_when_enabled *)
	rule collectdecoder;
		let x <- decoder.response.get;
		if(dcount == fromInteger(valueOf(P))-1)begin
			Vector#(P, Coeff) v = newVector;
			for(Integer i=0;i<valueOf(P)-1;i=i+1)
				v[i] = dbuf[i];
			v[valueOf(P)-1] = unpack(x);
			idwt2d.request.put(v);
			dcount <= 0;
		end
		else begin
			dbuf[dcount] <= unpack(x);
			dcount <= dcount + 1;
		end
	endrule
	
	interface Put request = dwt2d.request;
	interface Get response = idwt2d.response;
endmodule


module [SceMiModule] mkSceMiLayer(Empty);
    //SceMi clock is used for Xactors. Fixed at 50MHz
    SceMiClockConfiguration conf = defaultValue;
    SceMiClockPortIfc clk_port_scemi <- mkSceMiClockPort(conf);

    DutInterface dut <- buildDutWithSoftReset(mkDutWrapper, clk_port_scemi);

    Empty datalink <- mkServerXactor(dut, clk_port_scemi);

    Empty shutdown <- mkShutdownXactor();
endmodule


