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
import BRAMFIFO::*;

import CommTypes::*;
import FullPipeline::*;

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
	let m <- mkFullPipeline();
	FIFO#(Byte) ififo <- mkSizedBRAMFIFO(131072); // 512Kb
	FIFO#(Byte) ofifo <- mkSizedBRAMFIFO(131072); // 512Kb
	
	rule feed;
		let x = ififo.first; ififo.deq;
		m.data.request.put(x);
	endrule
	
	rule fetch;
		let y <- m.data.response.get;
		ofifo.enq(y);
	endrule

	interface Server data;
		interface Put request = toPut(ififo);
		interface Get response = toGet(ofifo);
	endinterface

	interface Put start = m.start;
	
	interface Get count = m.count;

	interface DDR3_Client ddr3client = m.ddr3client;
endmodule

module [SceMiModule] mkSceMiLayer ( SceMiLayer );

    SceMiClockConfiguration conf = defaultValue;

    SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);
    DutInterface dut <- buildDutWithSoftReset(mkDutWrapper, clk_port);

    Empty data <- mkServerXactor(dut.data, clk_port);
    Empty start <- mkPutXactor(dut.start, clk_port);
    Empty count <- mkGetXactor(dut.count, clk_port);

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

