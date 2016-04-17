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
import DWT2DML::*;

typedef 2048 N;
typedef 2048 M;
typedef 8 P;
typedef 3 L;
typedef Vector#(P, WSample) DWT_Line;

typedef DWT#(P) DutInterface;

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT2DML#(N,M,P,L) dwt2d <- mkDWT2DML;

	return dwt2d;
endmodule


module [SceMiModule] mkSceMiLayer(Empty);
    //SceMi clock is used for Xactors. Fixed at 50MHz
    SceMiClockConfiguration conf = defaultValue;
    SceMiClockPortIfc clk_port_scemi <- mkSceMiClockPort(conf);

    DutInterface dut <- buildDutWithSoftReset(mkDutWrapper, clk_port_scemi);

    Empty datalink <- mkServerXactor(dut, clk_port_scemi);

    Empty shutdown <- mkShutdownXactor();
endmodule


