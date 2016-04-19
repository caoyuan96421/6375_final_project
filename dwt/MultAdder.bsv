import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import FIFO::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;

/*
	Module for calculating vector multiply/add function
	y[i]=a[i]+coef*(b[i]+c[i])
*/

interface MultAdder#(numeric type n);
	method Vector#(n,WSample) request(Vector#(n,WSample) a, Vector#(n,WSample) b, Vector#(n,WSample) c);
endinterface

module mkMultAdder(DWTCoef coef, MultAdder#(n) ifc);
		
	method Vector#(n,WSample) request(Vector#(n,WSample) a, Vector#(n,WSample) b, Vector#(n,WSample) c);
		Vector#(n,WSample) x = ?;
		for(Integer i=0;i<valueOf(n);i=i+1)begin
			x[i] = a[i] + fxptTruncate(fxptMult(coef, b[i] + c[i]));
		end
		return x;
	endmethod
	
endmodule
/*
(* synthesize *)
module mkSizedMultAdder(MultAdder#(MULT_SIZE, WSample, DWTCoef));
	MultAdder#(MULT_SIZE, WSample, DWTCoef) m <- mkMultAdder;
	return m;
endmodule
*/
