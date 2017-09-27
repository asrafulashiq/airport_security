function x = calc_intens(I, loc)

if isempty(loc)
    loc = [1 size(I,1)];
end

if length(size(I))==3
    I = rgb2gray(I);
end

strt_loc = loc(1);
end_loc = loc(2);

x = [];
for i = strt_loc:end_loc
    x = [ x  mean(I(i, :)) ];
end

% [b,a] = butter(10,0.2);
% x = filter(b,a,x);


end