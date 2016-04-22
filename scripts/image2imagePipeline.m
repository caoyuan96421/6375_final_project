%image to compression to encode to decode script to check pipeline
%correctness, can get the files to send to the fpga between encode and
%decode

ImageFile = 'palm.jpg';
t =imread(ImageFile);
X = double(imread(ImageFile))/255;
N = size(X);

X = rgb2ycbcr(X); 
L = 3;
Y = waveletcdf97(X,L);
T = reshape(Y,[],1);
T = int16(T);
%coeffs = [0,3,-4,2,-1,-1,0,47,55,1,-1,2,-2,3,-3,-4,0,0,0,0,0,0,0];
[bits, bytes] = huffman_encode(T');
size(T')
[new_coeffs] = huffman_decode(bytes);
size(new_coeffs)
Y_n = reshape(new_coeffs,N);
R = waveletcdf97(Y,-L);
imshow(ycbcr2rgb(R));