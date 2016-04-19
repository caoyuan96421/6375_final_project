import ClientServer::*;
import FIFO::*;
import GetPut::*;
import DefaultValue::*;
import SceMi::*;
import Clocks::*;
import ResetXactor::*;
import Memory::*;
import SimMem::*;
import Xilinx::*;
import Vector::*;

import Types::*;
import MemTypes::*;
import Connectable::*;
import DDR3OutstandingLimit::*;

import CommTypes::*;
import CommPipeline::*;

typedef CommIfc DutInterface;

typedef Byte ToHost;
typedef Byte FromHost;

`ifdef DDR3
typedef DDR3_Client SceMiLayer;
`else
typedef Empty SceMiLayer;
`endif


(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
   let m <- mkCommPipeline();
   return m;
endmodule

module [SceMiModule] mkSceMiLayer ( SceMiLayer );

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    DutInterface dut <- buildDutWithSoftReset(mkDutWrapper, clk_port);

    Empty tohost <- mkGetXactor(toGet(dut.getByteOutput), clk_port);
    Empty fromhost <- mkPutXactor(toPut(dut.putByteInput), clk_port);
    Empty setmode <- mkPutXactor(toPut(dut.doInit), clk_port);

    Empty shutdown <- mkShutdownXactor();

    // cross ddr3 fifos from controlled clock into uncontrolled domain
    let uclock <- sceMiGetUClock;
    let ureset <- sceMiGetUReset;
    SyncFIFOIfc#(DDR3_Req) reqFifo <- mkSyncFIFO(2, clk_port.cclock, clk_port.creset, uclock);
    SyncFIFOIfc#(DDR3_Resp) respFifo <- mkSyncFIFO(2, uclock, ureset, clk_port.cclock);
    mkConnectionOutstandingLimit( dut.ddr3client , toGPServer( reqFifo, respFifo ),
				 clocked_by clk_port.cclock, reset_by clk_port.creset);
`ifdef DDR3
	// FPGA synthesis, return to mkBridge and connecto real DDR3
    return toGPClient( reqFifo, respFifo );
`else
	// simulation
	mkSimMem(toGPClient(reqFifo, respFifo));
   `endif
endmodule

