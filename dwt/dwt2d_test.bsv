import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import DWT1DS::*;
import DWT2DS::*;
import DWTTypes::*;

typedef 16 L;
typedef 16 M;
typedef 4 B;

      
// Unit test for DWT module
(* synthesize *)
module mkDWT2DTest (Empty);
	DWT1D#(B) dwt1d <- mkDWT1DS;
	DWT2D#(B) dwt2d <- mkDWT2DS(dwt1d);
	
	Reg#(Bool) m_inited <- mkReg(False);
    Reg#(File) m_in <- mkRegU();
    Reg#(File) m_out <- mkRegU();
    Reg#(Bool) m_doneread <- mkReg(False);
	Reg#(Bit#(32)) m_sample_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_out <- mkReg(0);
	
	rule init(!m_inited);
		m_inited <= True;
		dwt2d.start(fromInteger(valueOf(L)), fromInteger(valueOf(M)));
		$display("%t Start",$time);
		
		m_sample_in <= fromInteger(valueOf(L)/valueOf(B));
    endrule


    rule read(m_inited && m_line_in < fromInteger(valueOf(M)));
        //$display("Send in line %d", m_line_in);
        Vector#(B, Sample) x;
        
        $write("%t Input %d %d: ", $time, m_line_in, m_sample_in);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
			x[i] = truncate(fromInteger(i)+fromInteger(valueOf(B))*(fromInteger(valueOf(L)/valueOf(B))-m_sample_in) + fromInteger(valueOf(L))*m_line_in + 1);
			$write("%d ",x[i]);
        end
        $display("");
        
        dwt2d.data.request.put(toWSample(x));
        
        if(m_sample_in == 1)begin    
	        m_line_in <= m_line_in + 1;
	        m_sample_in <= fromInteger(valueOf(L)/valueOf(B));
	    end
	    else 
	    	m_sample_in <= m_sample_in - 1;
    endrule
    
    rule write(m_inited && m_line_out < fromInteger(valueOf(M)*valueOf(B)));
    	let x <- dwt2d.data.response.get();
    	
    	$write("Output %d: ", m_line_out);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
			fxptWrite(4,x[i]);$write(" ");
        end
        $display("");
    
    	m_line_out <= m_line_out + 1;
    endrule
    
    rule finish(m_inited && m_line_in == fromInteger(valueOf(M)) && m_line_out == fromInteger(valueOf(M)*valueOf(B)));
//    	$fclose(m_in);
//    	$fclose(m_out);
    	$display("Done");
    	$finish;
    endrule
endmodule
