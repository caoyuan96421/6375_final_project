import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;
import ResetXactor::*;
import Xilinx::*;
import Vector::*;

import DWTTypes::*;
import DWT1DS::*;
import DWT2DS::*;

typedef 8 N;
typedef Vector#(N, WSample) DWT_Line;

interface DutInterface;
	interface DWT#(N) data;
	interface Put#(Tuple2#(Size_sample,Size_line)) start;
endinterface

(* synthesize *)
module mkDWT1DSFixed(DWT1D#(N));
	DWT1D#(N) m <- mkDWT1DS;
	return m;
endmodule

(* synthesize *)
module mkDWT2DSFixed(DWT2D#(N));
    DWT1D#(N) dwt1d <- mkDWT1DSFixed;
	DWT2D#(N) m <- mkDWT2DS(dwt1d);
	return m;
endmodule

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT2D#(N) dwt2d <- mkDWT2DSFixed;

	interface DWT data = dwt2d.data;
	interface Put start;
		method Action put(Tuple2#(Size_sample,Size_line) t) = dwt2d.start(tpl_1(t), tpl_2(t));
	endinterface
endmodule


module [SceMiModule] mkSceMiLayer(Empty);
    //SceMi clock is used for Xactors. Fixed at 50MHz
    SceMiClockConfiguration conf = defaultValue;
    SceMiClockPortIfc clk_port_scemi <- mkSceMiClockPort(conf);

    DutInterface dut <- buildDutWithSoftReset(mkDutWrapper, clk_port_scemi);

    Empty datalink <- mkServerXactor(dut.data, clk_port_scemi);
    Empty start <- mkPutXactor(dut.start, clk_port_scemi);

    Empty shutdown <- mkShutdownXactor();
endmodule


