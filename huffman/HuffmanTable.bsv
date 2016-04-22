import Vector::*;

typedef struct {
	Bit#(6) size;
	Bit#(m) tag;
	Bit#(n) token;
} HuffmanTableItem#(numeric type m, numeric type n) deriving (Bits,Eq);

// s: table length, m: tag length, n: max token length
typedef Vector#(s, HuffmanTableItem#(m, n)) HuffmanTable#(numeric type s, numeric type m, numeric type n);

HuffmanTable#(8, 12, 6) huffmanTable1 = cons(
HuffmanTableItem{size:2, tag: 0, token: 6'b100000}, cons(
HuffmanTableItem{size:4, tag: 1, token: 6'b110000}, cons(
HuffmanTableItem{size:4, tag:-1, token: 6'b110100}, cons(
HuffmanTableItem{size:5, tag: 2, token: 6'b111000}, cons(
HuffmanTableItem{size:5, tag:-2, token: 6'b111010}, cons(
HuffmanTableItem{size:6, tag: 3, token: 6'b111100}, cons(
HuffmanTableItem{size:6, tag:-3, token: 6'b111101}, cons(
HuffmanTableItem{size:6, tag:-4, token: 6'b111110},
nil))))))));
