import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import GetPut::*;

// Image Sample
typedef Bit#(12) Sample;

// Wavelet Transformed sample
typedef 12 WI;
typedef 20 WF;
typedef FixedPoint#(WI,WF) WSample;
typedef FixedPoint#(2,WF) DWTCoef;

// Sizes
typedef 2048 MAX_SAMPLE;
typedef 2048 MAX_LINE;
typedef 8 BLOCK_SIZE;


typedef Bit#(TAdd#(TLog#(n),1)) Size_t#(numeric type n);

typedef Size_t#(MAX_LINE) Size_line;
typedef Size_t#(MAX_SAMPLE) Size_sample;

// Array with size information. n is maximum size
//typedef Tuple2#(Size_t#(n),Vector#(n,t)) Line#(numeric type n,type t);

/*typedef Server#(
	Line#(n,Sample),
	Vector#(n,WSample)
) DWT1D#(numeric type n);*/

typedef Server#(
	Vector#(n, WSample),
	Vector#(n, WSample)
) DWT#(numeric type n);

interface DWT1D#(numeric type n);
	interface DWT#(n) data;
	method Action start(Size_sample l);
endinterface

interface DWT2D#(numeric type n);
	interface DWT#(n) data;
	method Action start(Size_sample l, Size_line m);
endinterface

// Convert Sample in to WSample
function Vector#(n,WSample) toWSample(Vector#(n,Sample) in);
	Vector#(n, WSample) out = replicate(0);
	for(Integer i=0; i<valueOf(n); i=i+1) begin
		out[i] = fromInt(unpack(in[i]));
	end
	return out;
endfunction

Real cdf97_LiftFilter_a = -1.5861343420693648;
Real cdf97_LiftFilter_b = -0.0529801185718856;
Real cdf97_LiftFilter_c = 0.8829110755411875;
Real cdf97_LiftFilter_d = 0.4435068520511142;
Real cdf97_ScaleFactor = 1.1496043988602418;



