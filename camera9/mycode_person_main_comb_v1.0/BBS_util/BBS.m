function [max_v, bb_new, ov] = BBS(Ir, bb)

Iref = im2single(imresize(imread('pair001_frm1.jpg'),0.5));
rect = double([10 91 152 108]);
T = imcrop(Iref, rect);
Ir = im2single(Ir);
bb_p = bb;

bb(1) = 1;
bb(3) = size(Ir,1);
bb(2) = bb(2) - 30;
bb(4) = bb(4) + 60;
bb(3) = max(size(T,1)+10, bb(3));
bb(4) = max(size(T,2)+10, bb(4));

I = imcrop(Ir, bb);


gamma = 2; % weighing coefficient between Dxy and Drgb
pz = 7;
%% adjust image and template size so they are divisible by the patch size 'pz'
[I,T,rect,Iref] = adjustImageSize(I,T,rect,Iref,pz);
szT = size(T);  szI = size(I);

%% run BBS
BBS = computeBBS(I,T,gamma, pz);
% interpolate likelihood map back to image size 
BBS = BBinterp(BBS, szT(1:2), pz, NaN);
%fprintf('BBS computed in %.2f sec (|I| = %dx%d , |T| = %dx%d)\n',t,szI(1:2),szT(1:2));

%% find target position in image (max BBS)
[rectOut] = findTargetLocation(BBS,'max',rect(3:4));

max_v = max(BBS(:));

bb_new = rectOut + [bb(1) bb(2) 0 0];

ov = bboxOverlapRatio(bb_p, bb_new);

end