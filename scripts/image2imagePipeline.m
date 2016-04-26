%image to compression to encode to decode script to check pipeline
%correctness, can get the files to send to the fpga between encode and
%decode
% 
ImageFile = 'saturn_256.jpg';
%t =imread(ImageFile);
X = double(imread(ImageFile))/255;
N = size(X);
X = padarray(X,[256-N(1),256-N(2),0],'post');


%X = rgb2ycbcr(X);
%X = X(:,:,1);
%X = ones(8);
%X = randi([-4,3],8,8)
N = size(X);
L = 3;
Y = waveletcdf97(X,L);
% for i=1:L
%     Y=scramble(Y, i);
% end
for i = 1:N(1)
    f = (i-1)*N(1)+1;
    s = (i)*N(1);
    T(f:s) = Y(i,:);
end
%T = reshape(Y,[],1);
T = int16(T);
size(T)
coeffs = [1,-1,-1,-4,-5,1,0,1,0,3,2,-2,3,0,-7];
[bytes] = huffman_encode(T); %T
size(bytes)
[new_coeffs] = huffman_decode(bytes);
out_coeffs = double(new_coeffs');
size(new_coeffs)
Y_n = zeros(N(1),N(2));
for i = 1:N(1)
    f = (i-1)*N(1)+1;
    s = (i)*N(1);
    Y_n(i,:) = new_coeffs(f:s);
end
%Y_n = double(reshape(out_coeffs,[8 8]));
R = waveletcdf97(Y_n,-L);
imshow(R);
