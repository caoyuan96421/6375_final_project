
N = [512,512];

f = fopen('in.pcm','rb');
bytes = fread(f);
fclose(f);
bytes = uint8(bytes);
L = 3;
[new_coeffs,b1] = huffman_decode(bytes', 8, prod(N)*3);
fprintf('Decoded\n');
nc = length(new_coeffs)/3;
new_coeffs = new_coeffs * 16;
Y_R_n = reshape(new_coeffs(1:nc),fliplr(N))';
Y_G_n = reshape(new_coeffs(nc+1:2*nc),fliplr(N))';
Y_B_n = reshape(new_coeffs(2*nc+1:3*nc),fliplr(N))';
for j=1:L
    Y_R_n=unscramble(Y_R_n, L-j);
    Y_G_n=unscramble(Y_G_n, L-j);
    Y_B_n=unscramble(Y_B_n, L-j);
end
O_R = waveletcdf97(Y_R_n,-L);
O_G = waveletcdf97(Y_G_n,-L);
O_B = waveletcdf97(Y_B_n,-L);
clear O
O(:,:,1) = uint8(O_R(:,:) + 128);
O(:,:,2) = uint8(O_G(:,:) + 128);
O(:,:,3) = uint8(O_B(:,:) + 128);
O(:) = uint8(O(:));

figure;
imshow(O);