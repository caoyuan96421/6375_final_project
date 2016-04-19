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

typedef 256 N;
typedef 8 B;
typedef Vector#(B, WSample) DWT_Line;

interface DutInterface;
	interface Server#(
    	DWT_Line,
		DWT_Line
	) data;
	interface Put#(Size_sample) start;
endinterface

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT1D#(B) m <- mkDWT1DS;
    interface Server data = m.data;
    interface Put start;
    	method Action put(Size_sample l) = m.start(l);
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


