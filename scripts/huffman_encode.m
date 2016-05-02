function [ bytes,bits ] = huffman_encode( coeffs )
%huffman encoding algorithm
%   bits are bit values, useful for debug comparisions
%   bytes can be written to file and sent to fpga

bits=[];
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
            nB_temp = size(co);
            if (nB_temp(2) > 12)
                co = co(:,1:12);
            end
            nB = size(co);
            %co = fliplr(co);
            for j = 1:(12-nB(2))
                bits = [bits , uint8(0)];
            end
            co = fliplr(co);
            bits = [bits , co];
            
    end
end
numBits = length(bits);
fprintf('Encoder output %d bits\n', numBits);
if (mod(numBits,4) ~= 0)
    r = mod(numBits,4); 
    for k = 1:(4-r)
        bits = [bits, uint8(0)];
    end
    fprintf('Encoder pad %d bits\n', 4-r);
end

bytes = bi2de(reshape(bits,4,[])')';
end

