import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import DWT1D::*;
import DWTTypes::*;

typedef 8 N;
      
typedef 4 B;
typedef TDiv#(N, B) M;

Integer t=32;

// Took 137 cycles for 16*8=128 conversions -> approaching one conversion/cycle because of fully pipelining
      
// Unit test for DWT module
(* synthesize *)
module mkDWT1DSTest (Empty);
	DWT1D#(N,B) dwt1d <- mkIDWT1D();
	
	Reg#(Bool) m_inited <- mkReg(False);
    Reg#(Bool) m_doneread <- mkReg(False);
	Reg#(Bit#(32)) m_line_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_out <- mkReg(0);
	Reg#(Bit#(4)) flip <- mkReg(0);	
	rule init(!m_inited);
		m_inited <= True;
		$display("Start @ %t",$time);
    endrule


    rule read(m_inited && m_line_in < fromInteger(t*valueOf(M)));
        $display("%t Feed line %d", $time, m_line_in);
        if(flip==0) begin
		    Vector#(B, Sample) x;
		    $write("%t Input %d: ", $time, m_line_in);
		    for(Integer i=0;i<valueOf(B);i=i+1)begin
				x[i] = truncate(fromInteger(i)+fromInteger(valueOf(B))*m_line_in + 1);
				$write("%d ",x[i]);
		    end
		    $display("");
		    
		    dwt1d.request.put(toWSample(x));
		    
		    m_line_in <= m_line_in + 1;
		end
		//flip <= flip+1;
    endrule
    
    rule write(m_inited && m_line_out < fromInteger(t*valueOf(M)));
    	let x <- dwt1d.response.get();
    	
    	$write("%t Output %d: ", $time, m_line_out);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
			fxptWrite(4,x[i]);$write(" ");
        end
        $display("");
    
    	m_line_out <= m_line_out + 1;
    endrule
    
    rule finish(m_inited && m_line_in == fromInteger(t*valueOf(M)) && m_line_out == fromInteger(t*valueOf(M)));
    	$display("%t Done", $time);
    	$finish;
    endrule
endmodule
