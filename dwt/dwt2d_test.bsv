import ClientServer::*;
import GetPut::*;
import Vector::*;
import FixedPoint::*;
import FIFO::*;
import FShow::*;
import DWT2D::*;
import DWT2DML::*;
import DWTTypes::*;
import Encoder_v2::*;
import Decoder_v2::*;
import HuffmanTable::*;
import CommTypes::*;

typedef 8 N;
typedef 8 M;
typedef 2 B;
typedef 1 T;
typedef 3 L;

      
// Unit test for DWT module
(* synthesize *)
module mkDWT2DTest (Empty);
	DWT2DMLI#(N,M,B,L) dwt2d <- mkDWT2DMLI();
	IDWT2DMLI#(N,M,B,L) idwt2d <- mkIDWT2DMLI();
	Encoder#(WC, 4) encoder <- mkEncoder(huffmanTable1);
	Decoder#(4, WC) decoder <- mkDecoder(huffmanTable1);
	FIFO#(Vector#(B, Coeff)) efifo <- mkFIFO;
	Vector#(B, Reg#(Coeff)) dbuf <- replicateM(mkRegU);
	
	
	Reg#(Bool) m_inited <- mkReg(False);
	Reg#(File) m_in <- mkRegU();
	Reg#(File) m_out <- mkRegU();
	Reg#(Bool) m_doneread <- mkReg(False);
	Reg#(Bit#(32)) m_sample_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_in <- mkReg(0);
	Reg#(Bit#(32)) m_line_out <- mkReg(0);
	Reg#(Bit#(4)) t <- mkReg(0);
	Reg#(Bit#(4)) ecount <- mkReg(0);
	Reg#(Bit#(4)) dcount <- mkReg(0);
	
	rule init(!m_inited);
		m_inited <= True;
		$display("%t Start",$time);
		
		m_sample_in <= fromInteger(valueOf(N)/valueOf(B));
    endrule

	(* fire_when_enabled *)
	rule dwt2huffman;
		let x <- dwt2d.response.get();
		//encoder.request.put(x);
		efifo.enq(x);
        $display("%t to   Huffman:",$time, fshow(x));
		//idwt2d.request.put(x);
	endrule
	
	(* fire_when_enabled *)
	rule feedencoder;
		let x = efifo.first;
		encoder.request.put(pack(x[ecount]));
		if(ecount == fromInteger(valueOf(B))-1)begin
			ecount <= 0;
			efifo.deq;
		end
		else begin
			ecount <= ecount + 1;
		end
	endrule
	
	rule encoder2decoder;
		let x <- encoder.response.get();
		decoder.request.put(x);
	endrule
	
	rule collectdecoder;
		let x <- decoder.response.get;
		if(dcount == fromInteger(valueOf(B))-1)begin
			Vector#(B, Coeff) v = newVector;
			for(Integer i=0;i<valueOf(B)-1;i=i+1)
				v[i] = dbuf[i];
			v[valueOf(B)-1] = unpack(x);
			idwt2d.request.put(v);
			dcount <= 0;
		end
		else begin
			dbuf[dcount] <= unpack(x);
			dcount <= dcount + 1;
		end
	endrule
	
	/*(* fire_when_enabled *)
	rule huffman2idwdt;
		let x <- huffman.response.get();
		idwt2d.request.put(x);
        $display("%t from Huffman:",$time, fshow(x));
	endrule*/

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
    /*rule receive_decoder(m_inited);
    	let x <- decoder.response.get();
    	
    	$write("Output %d: %d", m_line_out, x);
        $display("");
    
    	m_line_out <= m_line_out + 1;
    endrule*/
    
    
    rule flush(m_inited && t==fromInteger(valueOf(T)));
    	// Keep Flushing with junk when done
    	$display("%t Flush",$time);
    	dwt2d.request.put(replicate(0));
    endrule
    
    rule finish(m_inited && m_line_out == fromInteger(valueOf(N)*valueOf(M)/valueOf(B)*valueOf(T)));
    	$display("Done at %t", $time);
    	$finish;
    endrule
endmodule
