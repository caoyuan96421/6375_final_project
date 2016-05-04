function [ coeffs,bits ] = huffman_decode( bytes, maxlen, expected)
bits = reshape(de2bi(bytes)',1,[]);
lenBits = length(bits);
coeffs = zeros(1, expected);

fprintf('Decoder input %d bits\n', lenBits);

i = 1;
j = 1;
while ( i < lenBits)
    if (i+1 == lenBits || i+2 == lenBits || i+3 == lenBits)
        i = lenBits;
    elseif (bits(i:i+1) == [1 0])
        coeffs(j) = 0;
        i = i + 2;
    elseif (bits(i:i+3) == [1 1 0 0])
        coeffs(j) = 1;
        i = i + 4;
    elseif (bits(i:i+3) == [1 1 0 1])
        coeffs(j) = -1;
        i = i + 4;
    elseif (bits(i:i+4) == [1 1 1 0 0])
        coeffs(j) = 2;
        i = i + 5;
    elseif (bits(i:i+4) == [1 1 1 0 1])
        coeffs(j) = -2;
        i = i + 5;
    elseif (bits(i:i+5) == [1 1 1 1 0 0])
        coeffs(j) = 3;
        i = i + 6;
    elseif (bits(i:i+5) == [1 1 1 1 0 1])
        coeffs(j) = -3;
        i = i + 6;
    elseif (bits(i:i+5) == [1 1 1 1 1 0])
        coeffs(j) = -4;
        i = i + 6;
    elseif (bits(i:i+5) == [1 1 1 1 1 1])
        test = bi2de(int16(bits(i+6:i+5+maxlen)), 'left-msb');
        if (test > 2^(maxlen-1))
            test = test - 2^maxlen;
        end
        %new_coeff = typecast(uint16(bin2dec(num2str(bits(i+6:i+17)))),'int16')
        coeffs(j) = test;
        i = i + 6 + maxlen;
    else
        fprintf('Error! at i = %d', int2str(i));
%         c1 = mat2str(bits(i:i+1))
%         c2 = mat2str(bits(i:i+3))
%         c3 = mat2str(bits(i:i+4))
%         c4 = mat2str(bits(i:i+5))
%         cN = typecast(uint16(bin2dec(fliplr(num2str(bits(i+6:i+21))))),'int16')
        i = lenBits;
    end
    
    j = j+1;
end
fprintf('Decoder decoded %d samples\n',j-1);
end
