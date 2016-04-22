function [ coeffs ] = huffman_decode( bytes )
bits = [];
coeffs= [];
len = size(bytes);
for i = 1:len(2)
    byte = bytes(i);
    switch(byte)
        case 0
            bits = [bits,0,0,0,0];
        case 1
            bits = [bits,1,0,0,0];
        case 2
            bits = [bits,0,1,0,0];
        case 3
            bits = [bits,1,1,0,0];
        case 4
            bits = [bits,0,0,1,0];
        case 5
            bits = [bits,1,0,1,0];
        case 6
            bits = [bits,0,1,1,0];
        case 7
            bits = [bits,1,1,1,0];
        case 8
            bits = [bits,0,0,0,1];
        case 9
            bits = [bits,1,0,0,1];
        case 10
            bits = [bits,0,1,0,1];
        case 11
            bits = [bits,1,1,0,1];
        case 12
            bits = [bits,0,0,1,1];
        case 13
            bits = [bits,1,0,1,1];
        case 14
            bits = [bits,0,1,1,1];
        case 15
            bits = [bits,1,1,1,1];
    end
end

lenBits = size(bits)
curr = [];
out_of_table = false;
for j = 1:lenBits(2)
    curr = [curr,bits(j)];
    str_curr = mat2str(curr);
    if (~out_of_table)
        switch (str_curr)
            case '[1 0]'
                coeffs = [coeffs,0];
                curr = [];
            case '[1 1 0 0]'
                coeffs = [coeffs,1];
                curr = [];
            case '[1 1 0 1]'
                coeffs = [coeffs,-1];
                curr = [];
            case '[1 1 1 0 0]'
                coeffs = [coeffs,2];
                curr = [];
            case '[1 1 1 0 1]'
                coeffs = [coeffs,-2];
                curr = [];
            case '[1 1 1 1 0 0]'
                coeffs = [coeffs,3];
                curr = [];
            case '[1 1 1 1 0 1]'
                coeffs = [coeffs,-3];
                curr = [];
            case '[1 1 1 1 1 0]'
                coeffs = [coeffs,-4];
                curr = [];
            case '[1 1 1 1 1 1]'
                curr = [];
                out_of_table = true;
            otherwise
                continue;
        end
    else
        s = size(curr);
        if (s(2) == 16)
            out_coeff = typecast(uint16(bin2dec(num2str(fliplr(curr)))),'int16');
            coeffs = [coeffs,out_coeff];
            curr = [];
            out_of_table = false;
        end
    end
end