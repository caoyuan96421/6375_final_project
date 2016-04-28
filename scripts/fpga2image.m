f = fopen('out.pcm','rb');
bytes = fread(f);
fclose(f);
bytes = uint8(bytes);
L = 3;
N = [256 256];
[new_coeffs,b1] = huffman_decode(bytes');
n_c = size(new_coeffs)
Y_n = zeros(N(1),N(2));
for i = 1:N(1)
    f = (i-1)*N(1)+1;
    s = (i)*N(1);
    s = min(n_c(2),s);
    Y_n(i,1:s+1-f) = new_coeffs(f:s);
end
for j=1:L
    Y_n=unscramble(Y_n, L-j);
end
R = waveletcdf97(Y_n,-L);
R = R + 128;
imshow(uint8(R));