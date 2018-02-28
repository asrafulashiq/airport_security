function [BBS] = runBBS(I,T,pz,gamma,verbose)
% run BBS coimputation including pre/post processing 

%% check input and set default BBS params
if nargin<5, verbose = 0; end
if nargin<4
    gamma = 2; % weighing coefficient between Dxy and Drgb
end
if nargin<3
    pz = 3; % non-overlapping patch size used for pixel descirption
end

%% adjust image and template size so they are divisible by the patch size 'pz'
szT = size(T);
mt = mod(szT(1:2),pz);
if(any(mt))
    T = T(1:end-mt(1),1:end-mt(2), :);
    rect(3:4) = rect(3:4)-mt;
end

szI = size(I);
mi = mod(szI(1:2),pz);
if(any(mi))
    I = I(1:end-mi(1),1:end-mi(2), :);
    Iref = Iref(1:end-mi(1),1:end-mi(2), :);
end
szT = size(T);
szI = size(I);

%% run BBS
tic;
BBS = computeBBS(I,T,gamma, pz);
% interpolate likelihood map back to image size 
BBS = BBinterp(BBS, szT(1:2), pz, NaN);
t = toc;
if verbose
    fprintf('BBS computed in %.2f sec (|I| = %dx%d , |T| = %dx%d)\n',t,szI(1:2),szT(1:2));
end