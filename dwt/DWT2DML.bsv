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
import DWT2D::*;
import BRAMFIFO::*;

// Maximum level = 7
module mkDWT2DML(DWT2DML#(n, m, p, l)) 
	provisos (	Add#(l, a__, 7), 
				Div#(n, TMul#(p, TExp#(l)), TDiv#(n, TMul#(p, TExp#(l)))),
				Div#(m, TExp#(l), TDiv#(m, TExp#(l))),
				Add#(1, b__, TMul#(p, TAdd#(WI, WF))),
				Add#(1, c__, TMul#(TDiv#(p,2), TAdd#(WI, WF))),
				Add#(TDiv#(p,2), TDiv#(p,2), p),
				Add#(1, d__, TDiv#(p,2)),
				Add#(1, e__, p)
				);
	
	Integer np = valueOf(n) / valueOf(p);
	
	Vector#(l, DWT#(p)) dwt2ds = newVector;
	if(valueOf(l)>0)begin DWT2D#(n, m, p) dwt <- mkDWT2D; dwt2ds[0] = dwt; end
	if(valueOf(l)>1)begin DWT2D#(TDiv#(n,2), TDiv#(m,2), p) dwt <- mkDWT2D; dwt2ds[1] = dwt; end
	if(valueOf(l)>2)begin DWT2D#(TDiv#(n,4), TDiv#(m,4), p) dwt <- mkDWT2D; dwt2ds[2] = dwt; end
	if(valueOf(l)>3)begin DWT2D#(TDiv#(n,8), TDiv#(m,8), p) dwt <- mkDWT2D; dwt2ds[3] = dwt; end
	if(valueOf(l)>4)begin DWT2D#(TDiv#(n,16), TDiv#(m,16), p) dwt <- mkDWT2D; dwt2ds[4] = dwt; end
	if(valueOf(l)>5)begin DWT2D#(TDiv#(n,32), TDiv#(m,32), p) dwt <- mkDWT2D; dwt2ds[5] = dwt; end
	if(valueOf(l)>6)begin DWT2D#(TDiv#(n,64), TDiv#(m,64), p) dwt <- mkDWT2D; dwt2ds[6] = dwt; end
	
	// For each additional level added, 4 more lines must be buffered in each level
	Vector#(l, FIFO#(Vector#(p, WSample))) buffer <- replicateM(mkSizedBRAMFIFO(5*valueOf(l)*np + 8));
	
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
					$write("%t DWTML: Level %d, %d %d -> next ", $time, i, line[i], sample[i]);
					// New LL component, send into next stage
					dwt2ds[i+1].request.put(x);
				end
				else begin
					$write("%t DWTML: Level %d, %d %d -> store ",$time, i, line[i], sample[i]);
					// store in buffer
					buffer[i].enq(x);
				end
`ifdef SIM
		//for(Integer j=0;j<valueOf(p);j=j+1)begin
		//	fxptWrite(4, x[j]);
		//	$write(" ");
		//end
		$display("");
`endif
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
