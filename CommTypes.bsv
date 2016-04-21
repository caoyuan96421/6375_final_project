import Vector::*;
import Complex::*;
import FixedPoint::*;
import Types::*;
import FShow::*;
import MemTypes::*;
import ClientServer::*;
import GetPut::*;

typedef Bit#(4) Byte;

typedef Vector#(6,Byte) Pixel;

typedef Vector#(16,Pixel) MemWord;

typedef Bit#(1024) Line;

typedef Bit#(512) MemData;

//typedef FixedPoint#(16,16) Coeff;
typedef 12 WC;
typedef Int#(WC) Coeff;

//typedef Bit#(24) Addr;
//add line type
typedef Server#(
	Byte, Byte
) ServerInterface;

interface CommIfc;
    method Action putByteInput(Byte in);
    method ActionValue#(Byte) getByteOutput();
    method Action doInit(Bool x);
    //interface ServerInterface serverinterface;
    interface DDR3_Client ddr3client;
    interface Put#(Bool) setmode;
    //interface WideMemInitIfc memInit;
endinterface

