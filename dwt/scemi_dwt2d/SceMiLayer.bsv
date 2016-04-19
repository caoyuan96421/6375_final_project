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
import DWT1D::*;
import DWT2D::*;
import DWT2DML::*;

typedef 1024 N;
typedef 1024 M;
typedef 8 P;
typedef 3 L;
typedef Vector#(P, WSample) DWT_Line;

typedef DWT#(P) DutInterface;

/*
(* synthesize *)
module mkDWT1D_8(DWT#(P));
	DWT1D#(8, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_16(DWT#(P));
	DWT1D#(16, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_32(DWT#(P));
	DWT1D#(32, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_64(DWT#(P));
	DWT1D#(64, P) m <- mkDWT1D;
	return m;
endmodule
*/

(* synthesize *)
module mkDWT1D_128(DWT#(P));
	DWT1D#(128, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_256(DWT#(P));
	DWT1D#(256, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_512(DWT#(P));
	DWT1D#(512, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT1D_1024(DWT#(P));
	DWT1D#(1024, P) m <- mkDWT1D;
	return m;
endmodule

/*
(* synthesize *)
module mkDWT1D_2048(DWT#(P));
	DWT1D#(2048, P) m <- mkDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_8(DWT#(P));
	DWT1D#(8, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_16(DWT#(P));
	DWT1D#(16, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_32(DWT#(P));
	DWT1D#(32, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_64(DWT#(P));
	DWT1D#(64, P) m <- mkIDWT1D;
	return m;
endmodule
*/

(* synthesize *)
module mkIDWT1D_128(DWT#(P));
	DWT1D#(128, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_256(DWT#(P));
	DWT1D#(256, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_512(DWT#(P));
	DWT1D#(512, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkIDWT1D_1024(DWT#(P));
	DWT1D#(1024, P) m <- mkIDWT1D;
	return m;
endmodule

/*
(* synthesize *)
module mkIDWT1D_2048(DWT#(P));
	DWT1D#(2048, P) m <- mkIDWT1D;
	return m;
endmodule

(* synthesize *)
module mkDWT2D_8(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_8;
	DWT2D#(8, 8, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_16(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_16;
	DWT2D#(16, 16, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_32(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_32;
	DWT2D#(32, 32, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_64(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_64;
	DWT2D#(64, 64, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule
*/

(* synthesize *)
module mkDWT2D_128(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_128;
	DWT2D#(128, 128, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_256(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_256;
	DWT2D#(256, 256, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_512(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_512;
	DWT2D#(512, 512, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkDWT2D_1024(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_1024;
	DWT2D#(1024, 1024, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

/*
(* synthesize *)
module mkDWT2D_2048(DWT#(P));
	DWT#(P) dwt1d <- mkDWT1D_2048;
	DWT2D#(2048, 2048, P) m <- mkDWT2DP(dwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_8(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_8;
	DWT2D#(8, 8, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_16(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_16;
	DWT2D#(16, 16, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_32(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_32;
	DWT2D#(32, 32, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_64(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_64;
	DWT2D#(64, 64, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule
*/

(* synthesize *)
module mkIDWT2D_128(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_128;
	DWT2D#(128, 128, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_256(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_256;
	DWT2D#(256, 256, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_512(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_512;
	DWT2D#(512, 512, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

(* synthesize *)
module mkIDWT2D_1024(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_1024;
	DWT2D#(1024, 1024, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule

/*
(* synthesize *)
module mkIDWT2D_2048(DWT#(P));
	DWT#(P) idwt1d <- mkIDWT1D_2048;
	DWT2D#(2048, 2048, P) m <- mkIDWT2DP(idwt1d);
	return m;
endmodule
*/

(* synthesize *)
module mkDWT2DMLStatic(DWT2DML#(N,M,P,L));
	Vector#(L, DWT#(P)) dwt2ds = newVector;
	if(valueOf(L)>0)begin dwt2ds[0] <- mkDWT2D_1024; end
	if(valueOf(L)>1)begin dwt2ds[1] <- mkDWT2D_512; end
	if(valueOf(L)>2)begin dwt2ds[2] <- mkDWT2D_256; end
	if(valueOf(L)>3)begin dwt2ds[3] <- mkDWT2D_128; end
	
	DWT2DML#(N,M,P,L) m <- mkDWT2DMLP(dwt2ds);
	
	return m;
endmodule

(* synthesize *)
module mkIDWT2DMLStatic(DWT2DML#(N,M,P,L));
	Vector#(L, DWT#(P)) idwt2ds = newVector;
	if(valueOf(L)>0)begin idwt2ds[0] <- mkIDWT2D_1024; end
	if(valueOf(L)>1)begin idwt2ds[1] <- mkIDWT2D_512; end
	if(valueOf(L)>2)begin idwt2ds[2] <- mkIDWT2D_256; end
	if(valueOf(L)>3)begin idwt2ds[3] <- mkIDWT2D_128; end
	
	DWT2DML#(N,M,P,L) m <- mkIDWT2DMLP(idwt2ds);
	
	return m;
endmodule

(* synthesize *)
module [Module] mkDutWrapper (DutInterface);
    DWT2DML#(N,M,P,L) dwt2d <- mkDWT2DMLStatic;
	DWT2DML#(N,M,P,L) idwt2d <- mkIDWT2DMLStatic;
	
	rule d2i;
		let x <- dwt2d.response.get;
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


