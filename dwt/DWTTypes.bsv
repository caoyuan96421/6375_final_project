import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import GetPut::*;

// Image Sample
typedef Bit#(12) Sample;

// Wavelet Transformed sample
typedef 14 WI;
typedef 22 WF;
typedef FixedPoint#(WI,WF) WSample;
typedef FixedPoint#(2,WF) DWTCoef;

// Sizes
typedef 2048 MAX_SAMPLE;
typedef 2048 MAX_LINE;
typedef 8 BLOCK_SIZE;


typedef Bit#(TLog#(n)) Size_t#(numeric type n);

typedef Server#(
	Vector#(p, WSample),
	Vector#(p, WSample)
) DWT#(numeric type p);

typedef DWT#(p) DWT1D#(numeric type n, numeric type p);
typedef DWT#(p) DWT2D#(numeric type n, numeric type m, numeric type p);
typedef DWT#(p) DWT2DML#(numeric type n, numeric type m, numeric type p, numeric type l);

/*interface DWT1D#(numeric type n);
	interface DWT#(n) data;
	method Action start(Size_sample l);
endinterface

interface DWT2D#(numeric type n);
	interface DWT#(n) data;
	method Action start(Size_sample l, Size_line m);
endinterface
*/

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



