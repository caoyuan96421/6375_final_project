function [ bits,bytes ] = huffman_encode( coeffs )
%huffman encoding algorithm
%   bits are bit values, useful for debug comparisions
%   bytes can be written to file and sent to fpga

bits=[];
bytes = [];
len = size(coeffs);
for i = 1:len(2)
    coeff = coeffs(1,i);
    switch(coeff)
        case 0
            bits = [bits , uint8(1),uint8(0)];
        case 1
            bits = [bits , uint8(1),uint8(1),uint8(0),uint8(0)];
        case -1
            bits = [bits , uint8(1),uint8(1),uint8(0),uint8(1)];
        case 2
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(0),uint8(0)];
        case -2
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(0),uint8(1)];
        case 3
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(0),uint8(0)];
        case -3
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(0),uint8(1)];
        case -4
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(1),uint8(0)];
        otherwise
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(1),uint8(1)];
            co = uint16(de2bi(typecast(int16(coeff),'uint16')));
            bits = [bits , co];
            nB = size(co);
            for j = 1:(16-nB(2))
                bits = [bits , uint8(0)];
            end
    end
end
numBits = size(bits)
if (mod(numBits(2),4) ~= 0)
    r = mod(numBits(2),4); 
    for k = 1:(4-r)
        bits = [bits, uint8(0)];
    end
end
for b = 1:4:numBits(2)
    %note that each byte is flipped to match how hardware processes.
    byte = mat2str(fliplr(bits(1,b:b+3)));
    switch(byte)
        case '[0 0 0 0]'
            bytes = [bytes, uint8(0)];
        case '[0 0 0 1]'
            bytes = [bytes, uint8(1)];
        case '[0 0 1 0]'
            bytes = [bytes, uint8(2)];
        case '[0 0 1 1]'
            bytes = [bytes, uint8(3)];
        case '[0 1 0 0]'
            bytes = [bytes, uint8(4)];
        case '[0 1 0 1]'
            bytes = [bytes, uint8(5)];
        case '[0 1 1 0]'
            bytes = [bytes, uint8(6)];
        case '[0 1 1 1]'
            bytes = [bytes, uint8(7)];
        case '[1 0 0 0]'
            bytes = [bytes, uint8(8)]; 
        case '[1 0 0 1]'
            bytes = [bytes, uint8(9)];
        case '[1 0 1 0]'
            bytes = [bytes, uint8(10)];
        case '[1 0 1 1]'
            bytes = [bytes, uint8(11)];
        case '[1 1 0 0]'
            bytes = [bytes, uint8(12)];
        case '[1 1 0 1]'
            bytes = [bytes, uint8(13)];
        case '[1 1 1 0]'
            bytes = [bytes, uint8(14)];
        case '[1 1 1 1]'
            bytes = [bytes, uint8(15)];
    end
end

