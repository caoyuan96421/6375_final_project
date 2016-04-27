function B = scramble(A,level)
    B=A;
    B(1:2^(level+1):end,1:size(A,2)/2^(level))=A(1:2^level:size(A,1)/2,1:size(A,2)/2^(level));
    B(1+2^level:2^(level+1):end,1:size(A,2)/2^(level))=A(size(A,1)/2+1:2^level:end,1:size(A,2)/2^(level));
end

