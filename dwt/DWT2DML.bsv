import Vector::*;
import Complex::*;
import FixedPoint::*;
import FShow::*;
import ClientServer::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import DWTTypes::*;
import MultAdder::*;
import CommTypes::*;
import DWT2D::*;
import BRAMFIFO::*;

typedef DWT#(p) DWT2DML#(numeric type n, numeric type m, numeric type p, numeric type l);

// Integer DWT interfaces
typedef Server#(
	Vector#(p, Sample),
	Vector#(p, Coeff)
) DWT2DMLI#(numeric type n, numeric type m, numeric type p, numeric type l);

typedef Server#(
	Vector#(p, Coeff),
	Vector#(p, Sample)
) IDWT2DMLI#(numeric type n, numeric type m, numeric type p, numeric type l);

// Quantized Sample
typedef Coeff QSample;

// Maximum level = 7
module mkDWT2DMLP(
		Vector#(l, DWT#(p)) dwt2ds,
		DWT2DML#(n, m, p, l) ifc
	) 
	provisos (	Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	
	Integer np = valueOf(n) / valueOf(p);
	
	// For each additional level added, 4 more lines in the LAST LEVEL must be buffered in each level
	Vector#(l, FIFO#(Vector#(p, WSample))) buffer <- replicateM(mkSizedBRAMFIFO(4*valueOf(TExp#(TSub#(l,1)))*np + 8));
	
	Vector#(l, Reg#(Size_t#(n))) sample <- replicateM(mkReg(0));
	Vector#(l, Reg#(Size_t#(m))) line <- replicateM(mkReg(0));	
	
	Integer t = 1; // = 2^i
	
	for(Integer i=0; i<valueOf(l); i=i+1)begin
	
		(* fire_when_enabled *)
		rule leveli;
			if((line[i] & fromInteger(t-1)) == 0 && sample[i] < fromInteger(np / t))begin
				// Result from highest level LL component 
				let x <- dwt2ds[i].response.get();
				if(i != valueOf(l)-1 && (line[i] & fromInteger(2*t - 1)) == 0 && sample[i] < fromInteger(np / (2*t)))begin
					$display("%t DWTML: Level %d, %d %d -> next ", $time, i, line[i], sample[i]);
					// New LL component, send into next stage
					dwt2ds[i+1].request.put(x);
				end
				else begin
					$display("%t DWTML: Level %d, %d %d -> store ",$time, i, line[i], sample[i]);
					// store in buffer
					buffer[i].enq(x);
				end
			$display("");
			end
			else if(i != 0)begin
				// HF components calculated in previous stages, just pass to next stage buffer
				$display("%t DWTML: Level %d, %d %d -> pass", $time, i, line[i], sample[i]);
				buffer[i].enq(buffer[i-1].first); buffer[i-1].deq;
			end
			
			if(sample[i] == fromInteger(valueOf(n) / valueOf(p) - 1))begin
				line[i] <= (line[i] == fromInteger(valueOf(m) - 1)) ? 0 : line[i] + 1;
				sample[i] <= 0;
			end
			else
				sample[i] <= sample[i] + 1;
		endrule
		
		t = t*2;
	end
	
	interface Put request = dwt2ds[0].request;
	interface Get response = toGet(buffer[valueOf(l)-1]);
endmodule


// Maximum level = 7
module mkIDWT2DMLP(
		Vector#(l, DWT#(p)) idwt2ds,
		DWT2DML#(n, m, p, l) ifc
	) 
	provisos (	Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	
	Integer np = valueOf(n) / valueOf(p);
	
	// For each additional level added, 5 more lines in the LAST LEVEL must be buffered in each level
		Vector#(l, FIFO#(Vector#(p, WSample))) buffer <- replicateM(mkSizedBRAMFIFO(5*valueOf(TExp#(TSub#(l,1)))*np + 8));
	
	Vector#(l, Reg#(Size_t#(n))) sample <- replicateM(mkReg(0));
	Vector#(l, Reg#(Size_t#(m))) line <- replicateM(mkReg(0));	
	
	Integer t = 1; // = 2^i
	
	for(Integer i=0; i<valueOf(l); i=i+1)begin
	
		(* fire_when_enabled *)
		rule leveli;
			if((line[i] & fromInteger(t-1)) == 0 && sample[i] < fromInteger(np / t))begin
				// Result from highest level LL component 
				let x = ?;
				if(i != fromInteger(valueOf(l)-1) && (line[i] & fromInteger(2*t - 1)) == 0 && sample[i] < fromInteger(np / (2*t)))begin
					$display("%t IDWTML: Level %d, %d %d -> previous ", $time, i, line[i], sample[i]);
					// New LL component, fetch from previous stage
					x <- idwt2ds[i+1].response.get;
				end
				else begin
					$display("%t IDWTML: Level %d, %d %d -> load ",$time, i, line[i], sample[i]);
					// load from buffer
					x = buffer[i].first; buffer[i].deq;
				end
				idwt2ds[i].request.put(x);
			end
			else if(i != 0)begin
				$display("%t IDWTML: Level %d, %d %d -> pass", $time, i, line[i], sample[i]);
				buffer[i-1].enq(buffer[i].first); buffer[i].deq;
			end
			
			if(sample[i] == fromInteger(valueOf(n) / valueOf(p) - 1))begin
				line[i] <= (line[i] == fromInteger(valueOf(m) - 1)) ? 0 : line[i] + 1;
				sample[i] <= 0;
			end
			else
				sample[i] <= sample[i] + 1;
		endrule
		
		t = t*2;
	end
	
	interface Put request = toPut(buffer[valueOf(l)-1]);
	interface Get response = idwt2ds[0].response;
endmodule


// Maximum level = 7
module mkDWT2DML(DWT2DML#(n, m, p, l))
			provisos (
				Add#(l, a__, 7),
				Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	Vector#(l, DWT#(p)) dwt2ds = newVector;
	if(valueOf(l)>0)begin DWT2D#(n, m, p) dwt <- mkDWT2D; dwt2ds[0] = dwt; end
	if(valueOf(l)>1)begin DWT2D#(TDiv#(n,2), TDiv#(m,2), p) dwt <- mkDWT2D; dwt2ds[1] = dwt; end
	if(valueOf(l)>2)begin DWT2D#(TDiv#(n,4), TDiv#(m,4), p) dwt <- mkDWT2D; dwt2ds[2] = dwt; end
	if(valueOf(l)>3)begin DWT2D#(TDiv#(n,8), TDiv#(m,8), p) dwt <- mkDWT2D; dwt2ds[3] = dwt; end
	if(valueOf(l)>4)begin DWT2D#(TDiv#(n,16), TDiv#(m,16), p) dwt <- mkDWT2D; dwt2ds[4] = dwt; end
	if(valueOf(l)>5)begin DWT2D#(TDiv#(n,32), TDiv#(m,32), p) dwt <- mkDWT2D; dwt2ds[5] = dwt; end
	if(valueOf(l)>6)begin DWT2D#(TDiv#(n,64), TDiv#(m,64), p) dwt <- mkDWT2D; dwt2ds[6] = dwt; end
	
	DWT2DML#(n, m, p, l) m <- mkDWT2DMLP(dwt2ds);
	
	return m;
endmodule

module mkIDWT2DML(DWT2DML#(n, m, p, l))
			provisos (	
				Add#(l, a__, 7),
				Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	Vector#(l, DWT#(p)) idwt2ds = newVector;
	if(valueOf(l)>0)begin DWT2D#(n, m, p) idwt <- mkIDWT2D; idwt2ds[0] = idwt; end
	if(valueOf(l)>1)begin DWT2D#(TDiv#(n,2), TDiv#(m,2), p) idwt <- mkIDWT2D; idwt2ds[1] = idwt; end
	if(valueOf(l)>2)begin DWT2D#(TDiv#(n,4), TDiv#(m,4), p) idwt <- mkIDWT2D; idwt2ds[2] = idwt; end
	if(valueOf(l)>3)begin DWT2D#(TDiv#(n,8), TDiv#(m,8), p) idwt <- mkIDWT2D; idwt2ds[3] = idwt; end
	if(valueOf(l)>4)begin DWT2D#(TDiv#(n,16), TDiv#(m,16), p) idwt <- mkIDWT2D; idwt2ds[4] = idwt; end
	if(valueOf(l)>5)begin DWT2D#(TDiv#(n,32), TDiv#(m,32), p) idwt <- mkIDWT2D; idwt2ds[5] = idwt; end
	if(valueOf(l)>6)begin DWT2D#(TDiv#(n,64), TDiv#(m,64), p) idwt <- mkIDWT2D; idwt2ds[6] = idwt; end
	
	DWT2DML#(n, m, p, l) m <- mkIDWT2DMLP(idwt2ds);
	
	return m;
endmodule

module mkDWT2DMLI(DWT2DMLI#(n, m, p, l))
			provisos (	
				Add#(l, a__, 7),
				Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	DWT2DML#(n, m, p, l) m <- mkDWT2DML;
	interface Put request;
		method Action put(Vector#(p, Sample) x);
			Vector#(p, WSample) y;
			for(Integer i=0; i<valueOf(p); i=i+1)begin
				y[i] = fromUInt(unpack(x[i])) - fromInteger(sample_shift);
			end
			m.request.put(y);
		endmethod
	endinterface
	interface Get response;
		method ActionValue#(Vector#(p, Coeff)) get();
			let x <- m.response.get();
			return fromWSample(x);
		endmethod
	endinterface
endmodule

module mkIDWT2DMLI(IDWT2DMLI#(n, m, p, l))
			provisos (	
				Add#(l, a__, 7),
				Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	DWT2DML#(n, m, p, l) m <- mkIDWT2DML;
	interface Put request;
		method Action put(Vector#(p, Coeff) x)=m.request.put(toWSample(x));
	endinterface
	interface Get response;
		method ActionValue#(Vector#(p, Sample)) get();
			let x <- m.response.get;
			Vector#(p, Sample) y = newVector;
			for(Integer i=0; i<valueOf(p); i=i+1)begin
				let t = fxptGetInt(x[i]) + fromInteger(sample_shift); // Full precision integer part
				Sample a = 0;
				// Saturation
				if(t < 0)
					y[i] = 0;
				else if(t >= fromInteger(2**valueOf(WS)))
					y[i] = fromInteger(2**valueOf(WS) - 1);
				else
					y[i] = pack(truncate(t));
			end
			return y;
		endmethod
	endinterface
endmodule
