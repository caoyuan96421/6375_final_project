S = 256;
% ImageFile = 'saturn_1024.jpg';
% t =imread(ImageFile);
% X = double(imread(ImageFile));
% N = size(X);
% X = padarray(X,[1024-N(1),1024-N(2),0],'post')-128;
% N = size(X)
% L = 3;

ImageFile = 'toysnoflash_256.png';
%t =imread(ImageFile);
X = imread(ImageFile);
% X = rgb2gray(X);
% N = size(X);
% X = padarray(X,[S-N(1),S-N(2),0],'post')-128;
% X = double(X);
% N = size(X);
N = size(X);
R = padarray(X(:,:,1),[S-N(1),S-N(2),0],'post')-128;
G = padarray(X(:,:,2),[S-N(1),S-N(2),0],'post')-128;
B = padarray(X(:,:,3),[S-N(1),S-N(2),0],'post')-128;

R = double(R);
G = double(G);
B = double(B);
N = size(R);
L = 3;
Y_R = waveletcdf97(R,L);
Y_G = waveletcdf97(G,L);
Y_B = waveletcdf97(B,L);
for i=1:L
    Y_R=scramble(Y_R, i-1);
    Y_G=scramble(Y_G, i-1);
    Y_B=scramble(Y_B, i-1);
end
% Y = waveletcdf97(X,L)Y = waveletcdf97(X,L);
% for i=1:L
%     Y=scramble(Y, i-1);
% end
T =[];
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
% for i =1:N(1)
%     f = (i-1)*N(1)+1;
%     s = (i)*N(1);
%     T(f:s) = Y(i,:);
% end
T = int16(T);
size(T)
coeffs = [0,3,-4,2,-1,-1,0,47,55,1,-1,2,-2,3,-3,-4,0,0,0,0,0,0,0];
[bytes,b0] = huffman_encode(T);
size(bytes)
%[bits, bytes] = huffman_encode(coeffs);
f = fopen('in.pcm','wb');
fwrite(f,bytes');
fclose(f);
