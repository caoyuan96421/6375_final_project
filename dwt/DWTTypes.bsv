import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import GetPut::*;

// Image Sample
typedef Int#(8) Sample;

// Wavelet Transformed sample
typedef 14 WI;
typedef 18 WF;
typedef FixedPoint#(WI,WF) WSample;
typedef FixedPoint#(2,WF) DWTCoef;

// Quantized Sample
typedef Int#(WI) QSample;

typedef Bit#(TLog#(n)) Size_t#(numeric type n);

typedef Server#(
	Vector#(p, WSample),
	Vector#(p, WSample)
) DWT#(numeric type p);

typedef DWT#(p) DWT1D#(numeric type n, numeric type p);
typedef DWT#(p) DWT2D#(numeric type n, numeric type m, numeric type p);
typedef DWT#(p) DWT2DML#(numeric type n, numeric type m, numeric type p, numeric type l);

// Integer DWT interfaces
typedef Server#(
	Vector#(p, Sample),
	Vector#(p, QSample)
) DWT2DMLI#(numeric type n, numeric type m, numeric type p, numeric type l);

typedef Server#(
	Vector#(p, QSample),
	Vector#(p, Sample)
) IDWT2DMLI#(numeric type n, numeric type m, numeric type p, numeric type l);

function Vector#(p,WSample) toWSample(Vector#(p,Int#(q)) v) provisos( Add#(q, a__, WI) );
	Vector#(p, WSample) x = replicate(0);
	for(Integer i=0; i<valueOf(p); i=i+1) begin
		x[i] = fromInt(v[i]);
	end
	return x;
endfunction

// Truncate WSample if necessary
function Vector#(p, Int#(q)) fromWSample(Vector#(p, WSample) x) provisos( Add#(q, a__, WI) );
	Vector#(p, Int#(q)) v = newVector;
	for(Integer i=0; i<valueOf(p); i=i+1)
		v[i] = unpack(truncate(pack(fxptGetInt(x[i]))));
	return v;
endfunction

Real cdf97_LiftFilter_a = -1.5861343420693648;
Real cdf97_LiftFilter_b = -0.0529801185718856;
Real cdf97_LiftFilter_c = 0.8829110755411875;
Real cdf97_LiftFilter_d = 0.4435068520511142;
Real cdf97_ScaleFactor = 1.1496043988602418;



