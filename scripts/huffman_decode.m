function [ coeffs,bits ] = huffman_decode( bytes )
bits = [];
coeffs= [];
len = size(bytes)
for i = 1:len(2)
    byte = bytes(i);
    switch(byte)
        case 0
            bits = [bits,0,0,0,0];
        case 1
            bits = [bits,1,0,0,0];
            %bits = [bits,0,0,0,1];
        case 2
            bits = [bits,0,1,0,0];
            %bits = [bits,0,0,1,0];
        case 3
            bits = [bits,1,1,0,0];
            %bits = [bits,0,0,1,1];
        case 4
            bits = [bits,0,0,1,0];
            %bits = [bits,0,1,0,0];
        case 5
            bits = [bits,1,0,1,0];
            %bits = [bits,0,1,0,1];
        case 6
            bits = [bits,0,1,1,0];
        case 7
            bits = [bits,1,1,1,0];
            %bits = [bits,0,1,1,1];
        case 8
            bits = [bits,0,0,0,1];
            %bits = [bits,1,0,0,0];
        case 9
            bits = [bits,1,0,0,1];
        case 10
            bits = [bits,0,1,0,1];
            %bits = [bits,1,0,1,0];
        case 11
            bits = [bits,1,1,0,1];
            %bits = [bits,1,0,1,1];
        case 12
            bits = [bits,0,0,1,1];
            %bits = [bits,1,1,0,0];
        case 13
            bits = [bits,1,0,1,1];
            %bits = [bits,1,1,0,1];
        case 14
            bits = [bits,0,1,1,1];
            %bits = [bits,1,1,1,0];
        case 15
            bits = [bits,1,1,1,1];
    end
end
lenBits = size(bits)

i = 1;
while ( i < lenBits(2))
    %i = i
    if (mat2str(bits(i:i+1)) == '[1 0]')
        coeffs = [coeffs,0];
        i = i + 2;
    elseif (i+1 == lenBits(2) || i+2 == lenBits(2))
        i = lenBits(2);
    elseif (mat2str(bits(i:i+3)) == '[1 1 0 0]')
        coeffs = [coeffs,1];
        i = i + 4;
    elseif (mat2str(bits(i:i+3)) == '[1 1 0 1]')
        coeffs = [coeffs,-1];
        i = i + 4;
    elseif (i+3 == lenBits(2))
        i = lenBits(2);
    elseif (mat2str(bits(i:i+4)) == '[1 1 1 0 0]')
        coeffs = [coeffs,2];
        i = i + 5;
    elseif (mat2str(bits(i:i+4)) == '[1 1 1 0 1]')
        coeffs = [coeffs,-2];
        i = i + 5;
    elseif (mat2str(bits(i:i+5)) == '[1 1 1 1 0 0]')
        coeffs = [coeffs,3];
        i = i + 6;
    elseif (mat2str(bits(i:i+5)) == '[1 1 1 1 0 1]')
        coeffs = [coeffs,-3];
        i = i + 6;
    elseif (mat2str(bits(i:i+5)) == '[1 1 1 1 1 0]')
        coeffs = [coeffs,-4];
        i = i + 6;
    elseif (mat2str(bits(i:i+5)) == '[1 1 1 1 1 1]')
        test = int16(bin2dec(num2str(bits(i+6:i+17))));
        if (test > 2^11)
            test = test - 2^12;
        end
        %new_coeff = typecast(uint16(bin2dec(num2str(bits(i+6:i+17)))),'int16')
        coeffs = [coeffs, test];
        i = i + 18;
    else
        error = ['Error! at i =' int2str(i)]
        c1 = mat2str(bits(i:i+1))
        c2 = mat2str(bits(i:i+3))
        c3 = mat2str(bits(i:i+4))
        c4 = mat2str(bits(i:i+5))
        cN = typecast(uint16(bin2dec(fliplr(num2str(bits(i+6:i+21))))),'int16')
        i = lenBits(2);
    end
end
end
