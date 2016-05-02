S = 256;
% ImageFile = 'saturn_1024.jpg';
% t =imread(ImageFile);
% X = double(imread(ImageFile));
% N = size(X);
% X = padarray(X,[1024-N(1),1024-N(2),0],'post')-128;
% N = size(X)
% L = 3;

ImageFile = 'toysnoflash.png';
%t =imread(ImageFile);
X = imread(ImageFile);
% X = rgb2gray(X);
% N = size(X);
% X = padarray(X,[S-N(1),S-N(2),0],'post')-128;
% X = double(X);
% N = size(X);
X = imresize(X, S/max(size(X)));
X = double(X);
N = size(X);
R = padarray(X(:,:,1),[S-N(1),S-N(2),0],'post')-128;
G = padarray(X(:,:,2),[S-N(1),S-N(2),0],'post')-128;
B = padarray(X(:,:,3),[S-N(1),S-N(2),0],'post')-128;

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
T = [reshape(Y_R', 1, []), reshape(Y_G', 1, []), reshape(Y_B', 1, [])];
T = int16(T);
size(T)
[bytes,b0] = huffman_encode(T);
size(bytes)
f = fopen('in.pcm','wb');
fwrite(f,bytes');
fclose(f);
