import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import DWT1DS::*;
import DWTTypes::*;

typedef 64 N;
      
typedef 8 B;
typedef TDiv#(N, B) M;
      
// Unit test for DWT module
(* synthesize *)
module mkDWT1DSTest (Empty);
	DWT1D#(B) dwt1d <- mkDWT1DS;
	
	Reg#(Bool) m_inited <- mkReg(False);
    Reg#(Bool) m_doneread <- mkReg(False);
	Reg#(Bit#(32)) m_line_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_out <- mkReg(0);
	Reg#(Bit#(4)) flip <- mkReg(0);	
	rule init(!m_inited);
		m_inited <= True;

		dwt1d.start(fromInteger(valueOf(N)));
		$display("Start @ %t",$time);
    endrule


    rule read(m_inited && m_line_in < fromInteger(valueOf(M)));
        //$display("Send in line %d", m_line_in);
        if(flip==0) begin
		    Vector#(B, Sample) x;
		    $write("%t Input %d: ", $time, m_line_in);
		    for(Integer i=0;i<valueOf(B);i=i+1)begin
				x[i] = truncate(fromInteger(i)+fromInteger(valueOf(B))*m_line_in + 1);
				$write("%d ",x[i]);
		    end
		    $display("");
		    
		    dwt1d.data.request.put(toWSample(x));
		    
		    m_line_in <= m_line_in + 1;
		end
		flip <= flip+1;
    endrule
    
    rule write(m_inited && m_line_out < fromInteger(valueOf(M)));
    	let x <- dwt1d.data.response.get();
    	
    	$write("%t Output %d: ", $time, m_line_out);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
			fxptWrite(4,x[i]);$write(" ");
        end
        $display("");
    
    	m_line_out <= m_line_out + 1;
    endrule
    
    rule finish(m_inited && m_line_in == fromInteger(valueOf(M)) && m_line_out == fromInteger(valueOf(M)));
    	$display("%t Done", $time);
    	$finish;
    endrule
endmodule
