function [I,T,rect,Iref] = adjustImageSize(I,T,rect,Iref,pz)

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
    Iref(1:end-mi(1),1:end-mi(2), :);    
end