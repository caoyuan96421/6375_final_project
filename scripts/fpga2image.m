f = fopen('out.pcm','rb');
bytes = fread(f);
fclose(f);
bytes = uint8(bytes);
L = 3;
N = [256 256]
%N = [1024 1024];
[new_coeffs,b1] = huffman_decode(bytes');
n_c = size(new_coeffs)
Y_R_n = zeros(N(1),N(2));
Y_G_n = zeros(N(1),N(2));
Y_B_n = zeros(N(1),N(2));
O = zeros(N(1),N(2),3);
for c = 1:3
    for i = 1:N(1)
        f = (i-1)*N(1)+1+(N(1)*(c-1))^2;
        s = (i)*N(1)+(N(1)*(c-1))^2;
        if (s < N(1)*N(1)*3)
            switch c
                case 1
                    Y_R_n(i,:) = new_coeffs(f:s);
                case 2
                    Y_G_n(i,:) = new_coeffs(f:s);
                case 3
                    Y_B_n(i,:) = new_coeffs(f:s);
            end
        end
    end
end
for j=1:L
    Y_R_n=unscramble(Y_R_n, L-j);
    Y_G_n=unscramble(Y_G_n, L-j);
    Y_B_n=unscramble(Y_B_n, L-j);
end
O_R = (waveletcdf97(Y_R_n,-L)+128)/255;
O_G = (waveletcdf97(Y_G_n,-L)+128)/255;
O_B = (waveletcdf97(Y_B_n,-L)+128)/255;
for i = 1:N(1)
    for j = 1:N(2)
        for c = 1:3
            switch c
                case 1
                    O(i,j,c) = O_R(i,j);
                case 2
                    O(i,j,c) = O_G(i,j);
                case 3
                    O(i,j,c) = O_B(i,j);
            end
        end
    end
end
imshow(O);