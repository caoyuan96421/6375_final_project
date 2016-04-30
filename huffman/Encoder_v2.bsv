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
) Encoder#(numeric type n_dwt, numeric type m_dwt, numeric type c, numeric type b);

typedef struct {
	Bit#(6) size;
	Bit#(n) token;
} Encoding#(numeric type n) deriving (Eq, Bits);

// s: Huffman Table length
// c: Input bit length
// n: Huffman encoding token length (excluding raw encoding)
// b: Output bit length
module mkEncoder(HuffmanTable#(s,c,n) ht, Encoder#(n_dwt, m_dwt, c, b) ifc);
	// Max length of each token
	Integer maxTokenLen = valueOf(n) + valueOf(c);
	Integer numSamples = valueOf(n_dwt) * valueOf(m_dwt);
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
	   samples <= samples + 1;
	   $display("samples:",samples);
	endrule

	rule stage_chunk (!isValid(bitBuffer[w_index + encodingFIFO.first.size - 1][1])); // Make sure there is enough room for write
		Encoding#(TAdd#(n, c)) encode = encodingFIFO.first; encodingFIFO.deq;
		for (Integer i = 0; i < maxTokenLen; i=i+1) begin
			if (fromInteger(i) < encode.size) begin
				bitBuffer[w_index + fromInteger(i)][1] <= tagged Valid encode.token[i];
			end
		end
		// Automatically warp
		w_index <= w_index + encode.size;
		$display("%t Encoder: chunk %b, w_ptr=%d", $time, encode.token, w_index);
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
	   $display("samples:",samples);
	   //for (Integer j = 0; j < 64; j=j+1) begin
	      //$display("bit buffer[%d]:",j, fshow(bitBuffer[j][0]));
	   //end
	   //$display("w index:%d r index:%d",w_index,r_index);
		outputFIFO.enq(out);
	endrule

   rule stage_pad((samples == fromInteger(numSamples)) && !isValid(bitBuffer[r_index + fromInteger(valueOf(b)) - 1][0]) && isValid(bitBuffer[r_index][0]));
      $display("in pad, r index:",r_index);
      Bit#(b) out = ?;
      for (Integer i = 0; i < valueOf(b); i=i+1) begin
	 out[i] = fromMaybe(0, bitBuffer[r_index + fromInteger(i)][0]);
	 bitBuffer[r_index + fromInteger(i)][0] <= tagged Invalid;
      end
		
      // Automatically warp
      r_index <= r_index + fromInteger(valueOf(b));
		
      $display("%t Encoder: output %b",$time, out);
      outputFIFO.enq(out);
   endrule
  
	interface Put request = toPut(inputFIFO);
	interface Get response = toGet(outputFIFO);

endmodule
// 