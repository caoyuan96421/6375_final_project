import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;
import Ehr::*;
import CommTypes::*;
import HuffmanTable::*;

typedef Server#(
	Bit#(b),
	Bit#(c)
)Decoder#(numeric type b, numeric type c);

module mkDecoder(HuffmanTable#(s, c, n)  ht, Decoder#(b,c) ifc);
	// Max length of each token
	Integer maxTokenLen = valueOf(n) + valueOf(c);
	
	FIFO#(Bit#(b)) inputFIFO <- mkFIFO;
	FIFO#(Bit#(c)) outputFIFO <- mkFIFO;

	Vector#(64,Ehr#(2, Maybe#(Bit#(1)))) bitBuffer <- replicateM(mkEhr(Invalid));
	Reg#(Bit#(6)) w_index <- mkReg(0);
	Reg#(Bit#(6)) r_index <- mkReg(0);
	
	rule stage_load (!isValid(bitBuffer[w_index + fromInteger(valueOf(b)) - 1][1]));
		let in = inputFIFO.first; inputFIFO.deq;
		for (Integer i = 0; i < valueOf(b); i=i+1) begin
			bitBuffer[w_index+fromInteger(i)][1] <= tagged Valid in[i];
		end
		// Automatically warp
		w_index <= w_index + fromInteger(valueOf(b));
		$display("%t Decoder: load %b", $time, in);
	endrule

	rule stage_decode (isValid(bitBuffer[r_index][0]));
		Vector#(n, Maybe#(Bit#(1))) tok = newVector;
		Bit#(n) ftok = ?;
		Bit#(c) out = ?;
		Bit#(6) size = ?;
		
		for(Integer i=0; i < valueOf(n); i = i+1)begin
			tok[i] = bitBuffer[r_index + fromInteger(i)][0];
			ftok[i] = fromMaybe(0, tok[i]);
		end
		Bool hit = False;
		for(Integer i=0; i < valueOf(s); i = i+1)begin
			Bool thishit = True;
			Bit#(n) rtoken = reverseBits(ht[i].token);
			for(Integer j=0; j < valueOf(n); j = j+1)begin
				if(fromInteger(j) < ht[i].size && (!isValid(tok[j]) || rtoken[j] != fromMaybe(?, tok[j])))begin
					// Missed
					thishit = False;
				end
			end
			if(thishit)begin
				hit = True;
				out = ht[i].tag;
				size = ht[i].size;
			end
		end
		// When we have out of table values, and the long token is ready to be fetched
		if(ftok=='1 && isValid(bitBuffer[r_index + fromInteger(maxTokenLen) - 1][0]))begin
			hit = True;
			for(Integer i=0; i<valueOf(c); i=i+1)begin
				out[i] = fromMaybe(?, bitBuffer[r_index + fromInteger(valueOf(n) + i)][0]);
			end
			out = reverseBits(out);
			size = fromInteger(maxTokenLen);
		end
		
		if(hit)begin
			// We're hit
			$display("%t Decoder: decode %b'%d -> %d", $time, ftok, size, out);
			outputFIFO.enq(out);
			for(Integer i=0; i<maxTokenLen; i=i+1)begin
				if(fromInteger(i) < size)begin
					bitBuffer[r_index + fromInteger(i)][0] <= tagged Invalid;
				end
			end
			r_index <= r_index + size;
		end
	endrule
      
	interface Put request = toPut(inputFIFO);
	interface Get response = toGet(outputFIFO);
endmodule
