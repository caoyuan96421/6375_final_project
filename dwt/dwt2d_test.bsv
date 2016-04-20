import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FShow::*;
import DWT2D::*;
import DWT2DML::*;
import DWTTypes::*;

typedef 32 N;
typedef 32 M;
typedef 4 B;
typedef 1 T;
typedef 3 L;

      
// Unit test for DWT module
(* synthesize *)
module mkDWT2DTest (Empty);
	DWT2DMLI#(N,M,B,L) dwt2d <- mkDWT2DMLI();
	IDWT2DMLI#(N,M,B,L) idwt2d <- mkIDWT2DMLI();
	
	Reg#(Bool) m_inited <- mkReg(False);
	Reg#(File) m_in <- mkRegU();
	Reg#(File) m_out <- mkRegU();
	Reg#(Bool) m_doneread <- mkReg(False);
	Reg#(Bit#(32)) m_sample_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_out <- mkReg(0);
	Reg#(Bit#(4)) t <- mkReg(0);
	
	rule init(!m_inited);
		m_inited <= True;
		$display("%t Start",$time);
		
		m_sample_in <= fromInteger(valueOf(N)/valueOf(B));
    endrule

	(* fire_when_enabled *)
	rule dwt2idwt;
		let x <- dwt2d.response.get();
		idwt2d.request.put(x);
	endrule

    rule send(m_inited && m_line_in < fromInteger(valueOf(M)) && t<fromInteger(valueOf(T)));
        //$display("Send in line %d", m_line_in);
        Vector#(B, Sample) x;
        
        $write("%t Input %d %d: ", $time, m_line_in, m_sample_in);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
			x[i] = unpack(truncate(fromInteger(i)+fromInteger(valueOf(B))*(fromInteger(valueOf(N)/valueOf(B))-m_sample_in) + fromInteger(valueOf(N))*m_line_in + 1));
			$write("%d ",x[i]);
        end
        $display("");
        
        dwt2d.request.put(x);
        
        if(m_sample_in == 1)begin    
	        m_line_in <= m_line_in + 1;
	        m_sample_in <= fromInteger(valueOf(N)/valueOf(B));
	    end
	    else 
	    	m_sample_in <= m_sample_in - 1;
    endrule
    
    rule newtest (m_inited && m_line_in == fromInteger(valueOf(M)));
    	m_line_in <= 0;
    	t <= t+1;
    	$display("Test case %d", t);
    endrule
    
    rule receive(m_inited && m_line_out < fromInteger(valueOf(N)*valueOf(M)/valueOf(B)*valueOf(T)));
    	let x <- idwt2d.response.get();
    	
    	$write("Output %d: ", m_line_out);
        for(Integer i=0;i<valueOf(B);i=i+1)begin
		$write("%d ", x[i]);
        end
        $display("");
    
    	m_line_out <= m_line_out + 1;
    endrule
    
    rule finish(m_inited && m_line_out == fromInteger(valueOf(N)*valueOf(M)/valueOf(B)*valueOf(T)) && t==fromInteger(valueOf(T)));
//    	$fclose(m_in);
//    	$fclose(m_out);
    	$display("Done");
    	$finish;
    endrule
endmodule
