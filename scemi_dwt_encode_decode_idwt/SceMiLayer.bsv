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
import DWTTypes::*;
import DWT1D::*;
import DWT2D::*;
import DWT2DML::*;

import Encoder::*;
import Decoder::*;
import HuffmanLoopBack::8;

typedef 1024 N;
typedef 1024 M;
typedef 8 P;
typedef 3 L;
typedef Vector#(P, Sample) DWT_Line;

typedef DWT#(P) DutInterface;

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT2DML#(N,M,P,L) dwt2d <- mkDWT2DMLI;
	DWT2DML#(N,M,P,L) idwt2d <- mkIDWT2DMLI;
	Encode#(P) encoder <- mkEncoder;
	Decode#(P) decoder <- mkDecoder;
	
	rule d2e;
		let x <- dwt2d.response.get;
		encoder.request.put(x);
	endrule
	
	rule e2d;
		let x <- encoder.response.get;
		decoder.response.put(x);
	endrule
	
	rule d2i;
		let x <- decoder.response.get(x);
		idwt2d.request.put(x);
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


