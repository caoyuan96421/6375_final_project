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

// Image pixel sample before level shifting, typically 0-255
typedef 8 WS;
typedef Bit#(WS) Sample;

// Wavelet Transform sample size, must be 2^(transformation level) larger than the sample size
typedef 14 WI;
typedef 18 WF;
typedef FixedPoint#(WI,WF) WSample;
typedef FixedPoint#(2,WF) DWTCoef;

typedef 8 WC;
typedef Int#(WC) Coeff;

interface CommIfc;
    interface Server#(Byte, Byte) data;
    interface Put#(Bit#(1)) start;
    interface Get#(Bit#(64)) count;
    interface DDR3_Client ddr3client;
endinterface

