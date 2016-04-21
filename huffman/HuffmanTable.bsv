import Vector::*;

typedef struct {
	Bit#(6) size;
	Bit#(m) tag;
	Bit#(n) token;
} HuffmanTableItem#(numeric type m, numeric type n) deriving (Bits,Eq);

// s: table length, m: tag length, n: max token length
typedef Vector#(s, HuffmanTableItem#(m, n)) HuffmanTable#(numeric type s, numeric type m, numeric type n);

HuffmanTable#(8, 12, 6) huffmanTable1 = cons(
HuffmanTableItem{size:2, tag: 0, token: 6'b01}, cons(
HuffmanTableItem{size:4, tag: 1, token: 6'b0011}, cons(
HuffmanTableItem{size:4, tag:-1, token: 6'b1011}, cons(
HuffmanTableItem{size:5, tag: 2, token: 6'b00111}, cons(
HuffmanTableItem{size:5, tag:-2, token: 6'b10111}, cons(
HuffmanTableItem{size:6, tag: 3, token: 6'b001111}, cons(
HuffmanTableItem{size:6, tag:-3, token: 6'b101111}, cons(
HuffmanTableItem{size:6, tag:-4, token: 6'b011111},
nil))))))));

/*
case (inCoeff)
			0: encoding[i] = Encoding{size:2,value:6'b000001, coeff: ?};       
			1: encoding[i] = Encoding{size:4,value:6'b000011, coeff: ?};
			-1:encoding[i] = Encoding{size:4,value:6'b001011, coeff: ?};
			2: encoding[i] = Encoding{size:5,value:6'b000111, coeff: ?};
			-2:encoding[i] = Encoding{size:5,value:6'b010111, coeff: ?};
			3: encoding[i] = Encoding{size:6,value:6'b001111, coeff: ?};
			-3:encoding[i] = Encoding{size:6,value:6'b101111, coeff: ?};
			-4:encoding[i] = Encoding{size:6,value:6'b011111, coeff: ?};
			default:encoding[i] = Encoding{size:22,value:6'b111111, coeff:inCoeffB};
			endcase
			*/
