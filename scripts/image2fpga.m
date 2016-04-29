ImageFile = 'saturn.png';
t =imread(ImageFile);
X = double(rgb2gray(imread(ImageFile)));
ns = [256, 256];
[I,J]=meshgrid(linspace(1,size(X,2),ns(1)),linspace(1,size(X,1),ns(2)));
X = interp2(X, I, J);%crop;padarray(X,[256-N(1),256-N(2),0],'post');
imshow(uint8(X));

X = X - 128;
%X = rgb2ycbcr(X); 
%X = X(:,:,1);
%X = randi([-4,3],8,8);
%X = ones(8);
N = size(X)
L = 3;
Y = waveletcdf97(X,L);
for i=1:L
    Y=scramble(Y, i-1);
end
T =[];
for i = 1:N(1)
    f = (i-1)*N(1)+1;
    s = (i)*N(1);
    T(f:s) = Y(i,:);
end
T = int16(T);
size(T)
coeffs = [0,3,-4,2,-1,-1,0,47,55,1,-1,2,-2,3,-3,-4,0,0,0,0,0,0,0];
[bytes,b0] = huffman_encode(T);
size(bytes)
%[bits, bytes] = huffman_encode(coeffs);
f = fopen('in.pcm','wb');
fwrite(f,bytes');
fclose(f);