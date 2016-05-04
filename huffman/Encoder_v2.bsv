import ClientServer::*;
import GetPut::*;
import FIFO::*;
import Vector::*;
import FixedPoint::*;
import HuffmanTable::*;
import CommTypes::*;
import Ehr::*;

typedef Server#(
	Bit#(c), // Coefficient input
	Bit#(b)  // Byte output
) Encoder#(numeric type ns, numeric type c, numeric type b);

typedef struct {
	Bit#(6) size;
	Bit#(t) token;
} Encoding#(numeric type t) deriving (Eq, Bits);

// s: Huffman Table length
// c: Input bit length
// n: Huffman encoding token length (excluding raw encoding)
// b: Output bit length
module mkEncoder(HuffmanTable#(s,c,n) ht, Encoder#(ns, c, b) ifc);
	// Max length of each token
	Integer maxTokenLen = valueOf(n) + valueOf(c);
	Integer numSamples = valueOf(ns);
	FIFO#(Bit#(c)) inputFIFO <- mkFIFO;
	FIFO#(Bit#(b)) outputFIFO <- mkFIFO; 
	
	// Encoding stuff
	FIFO#(Encoding#(TAdd#(n, c))) encodingFIFO <- mkFIFO; 
   Reg#(Bit#(32)) samples <-mkReg(0);
	// Chunking stuff
	Reg#(Bit#(6)) w_index <- mkReg(0);
	Reg#(Bit#(6)) r_index <- mkReg(0);
	Vector#(64,Ehr#(2, Maybe#(Bit#(1)))) bitBuffer <- replicateM(mkEhr(tagged Invalid));

	rule stage_encode;
		let in = inputFIFO.first; inputFIFO.deq;
		Bool hit = False;
		Encoding#(TAdd#(n, c)) encode = ?;
		// All tokens in the Huffman table are REVERSED
		for (Integer i = 0; i <  valueof(s); i=i+1) begin
			if ( in == ht[i].tag )begin
				encode = Encoding{size: ht[i].size, token: reverseBits({ht[i].token, '0})};
				hit = True;
			end
		end
		if(!hit)begin
			// Not found in encoding table, we just add 111...111 before the input
			encode = Encoding{size: fromInteger(maxTokenLen), token: reverseBits({'1, in})};
		end
		$display("%t Encoder: encode %d -> %bb'%d", $time, in, encode.token, encode.size);
	   encodingFIFO.enq(encode);
	endrule

	rule stage_chunk (!isValid(bitBuffer[w_index + encodingFIFO.first.size - 1][1])); // Make sure there is enough room for write
		Encoding#(TAdd#(n, c)) encode = encodingFIFO.first; encodingFIFO.deq;
		Bit#(TAdd#(TAdd#(n, c),4)) tok = extend(encode.token);
		Bit#(6) size = encode.size;
		if(samples == fromInteger(numSamples-1))begin
			// Check alignment
			if((w_index + size) % fromInteger(valueOf(b)) != 0)begin
				// Pad
				size = size + fromInteger(valueOf(b)) - (w_index + size) % fromInteger(valueOf(b));
				$display("%t Encoder: Pad %d zeros bits at the end of a frame", $time, fromInteger(valueOf(b)) - (w_index + size) % fromInteger(valueOf(b)));
			end
			samples <= 0;
		end
		else
			samples <= samples + 1;
		for (Integer i = 0; i < maxTokenLen + 4; i=i+1) begin
			if (fromInteger(i) < size) begin
				bitBuffer[w_index + fromInteger(i)][1] <= tagged Valid tok[i];
			end
		end
		// Automatically warp
		w_index <= w_index + size;
		$display("%t Encoder: chunk sample=%d size=%d tok=%b, w_ptr=%d", $time, samples, size, tok, w_index + size);
	endrule

	rule stage_read (isValid(bitBuffer[r_index + fromInteger(valueOf(b)) - 1][0])); // Make sure there is enough data to read
		Bit#(b) out = ?;
		for (Integer i = 0; i < valueOf(b); i=i+1) begin
			out[i] = fromMaybe(?, bitBuffer[r_index + fromInteger(i)][0]);
			bitBuffer[r_index + fromInteger(i)][0] <= tagged Invalid;
		end
		
		// Automatically warp
		r_index <= r_index + fromInteger(valueOf(b));
		
		$display("%t Encoder: output %b",$time, out);
		outputFIFO.enq(out);
	endrule

	/*rule stage_pad(samples == fromInteger(numSamples));
		if(!isValid(bitBuffer[r_index + fromInteger(valueOf(b)) - 1][0]) && isValid(bitBuffer[r_index][0])) begin
			// Some data left
			
			Bit#(b) out = ?;
			Bit#(6) new_r_index = ?;
			for (Integer i = valueOf(b) - 1; i >= 0; i=i-1) begin
				out[i] = fromMaybe(0, bitBuffer[r_index + fromInteger(i)][0]);
				if(!isValid(bitBuffer[r_index + fromInteger(i)][0]))begin
					new_r_index = r_index + fromInteger(i);
				end
				else
					bitBuffer[r_index + fromInteger(i)][0] <= tagged Invalid;
			end

			// Automatically warp
			r_index <= new_r_index;
			$display("%t Encoder: pad %d bits:",new_r_index - r_index);
			$display("%t Encoder: output %b",$time, out);
			outputFIFO.enq(out);
		end
		samples <= 0;
	endrule*/
  
	interface Put request = toPut(inputFIFO);
	interface Get response = toGet(outputFIFO);

endmodule
// 
