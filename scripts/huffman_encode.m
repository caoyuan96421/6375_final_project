function [ bytes,bits ] = huffman_encode( coeffs, maxlen )
%huffman encoding algorithm
%   bits are bit values, useful for debug comparisions
%   bytes can be written to file and sent to fpga

bits=[];
len = size(coeffs);
stat = zeros(1,9);
for i = 1:len(2)
    coeff = coeffs(1,i);
    switch(coeff)
        case 0
            bits = [bits , uint8(1),uint8(0)];
            stat(1) = stat(1) + 1;
        case 1
            bits = [bits , uint8(1),uint8(1),uint8(0),uint8(0)];
            stat(2) = stat(2) + 1;
        case -1
            bits = [bits , uint8(1),uint8(1),uint8(0),uint8(1)];
            stat(3) = stat(3) + 1;
        case 2
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(0),uint8(0)];
            stat(4) = stat(4) + 1;
        case -2
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(0),uint8(1)];
            stat(5) = stat(5) + 1;
        case 3
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(0),uint8(0)];
            stat(6) = stat(6) + 1;
        case -3
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(0),uint8(1)];
            stat(7) = stat(7) + 1;
        case -4
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(1),uint8(0)];
            stat(8) = stat(8) + 1;
        otherwise
            bits = [bits , uint8(1),uint8(1),uint8(1),uint8(1),uint8(1),uint8(1)];
            stat(9) = stat(9) + 1;
            co = uint16(de2bi(typecast(int16(coeff),'uint16')));
            nB_temp = size(co);
            if (nB_temp(2) > maxlen)
                co = co(:,1:maxlen);
            end
            nB = size(co);
            %co = fliplr(co);
            for j = 1:(maxlen-nB(2))
                bits = [bits , uint8(0)];
            end
            co = fliplr(co);
            bits = [bits , co];
            
    end
end
numBits = length(bits);
fprintf('Encoder output %d bits\n', numBits);
fprintf('Encoder statistics:\n');
disp([[0,1,-1,2,-2,3,-3,-4,100]; stat]);
fprintf('Ratio of full sample bits: %g\n', stat(end)*(6+maxlen)/numBits);
if (mod(numBits,4) ~= 0)
    r = mod(numBits,4); 
    for k = 1:(4-r)
        bits = [bits, uint8(0)];
    end
    fprintf('Encoder pad %d bits\n', 4-r);
end

bytes = bi2de(reshape(bits,4,[])')';
end

