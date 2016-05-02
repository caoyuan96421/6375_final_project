%image to compression to encode to decode script to check pipeline
%correctness, can get the files to send to the fpga between encode and
%decode
% 
S = 256;
ImageFile = 'toysnoflash_256.png';
%t =imread(ImageFile);
X = imread(ImageFile);
%X = rgb2gray(X);
N = size(X);
R = padarray(X(:,:,1),[S-N(1),S-N(2),0],'post')-128;
G = padarray(X(:,:,2),[S-N(1),S-N(2),0],'post')-128;
B = padarray(X(:,:,3),[S-N(1),S-N(2),0],'post')-128;
% R = [1, 0; 0, 0];
% G = [1, 0; 0, 0];
% B = [1, 0; 0, 0];

%X = double(X);
R = double(R);
G = double(G);
B = double(B);
N = size(R)
L = 3;
% imshow(X);
%Y = waveletcdf97(X,L);
Y_R = waveletcdf97(R,L);
Y_G = waveletcdf97(G,L);
Y_B = waveletcdf97(B,L);
for i=1:L
    Y_R=scramble(Y_R, i-1);
    Y_G=scramble(Y_G, i-1);
    Y_B=scramble(Y_B, i-1);
end
T = [];
for c = 1:3
    for i = 1:N(1)
        f = (i-1)*N(1)+1+(N(1)*(c-1))^2;
        s = (i)*N(1)+(N(1)*(c-1))^2;
        switch c
            case 1  
                T(f:s) = Y_R(i,:);
            case 2
                T(f:s) = Y_G(i,:);
            case 3
                T(f:s) = Y_B(i,:);
        end
    end
end
T = int16(T);
size(T)
coeffs = [1,-1,-1,-4,-5,1,0,1,0,3,2,-2,3,0,-7];
[bytes,b] = huffman_encode(T); %T
size(bytes)
[new_coeffs] = huffman_decode(bytes);
out_coeffs = double(new_coeffs');
size(new_coeffs)
Y_R_n = zeros(N(1),N(2));
Y_G_n = zeros(N(1),N(2));
Y_B_n = zeros(N(1),N(2));
O = zeros(N(1),N(2),3);
for c = 1:3
    for i = 1:N(1)
        f = (i-1)*N(1)+1+(N(1)*(c-1))^2;
        s = (i)*N(1)+(N(1)*(c-1))^2;
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
