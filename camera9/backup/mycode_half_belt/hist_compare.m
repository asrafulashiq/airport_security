function val = hist_compare(X,Y)

    [c1,~]=imhist(X);
    [c2,~]=imhist(Y);
    c1 = c1(100:200);
    c2 = c2(100:200);
    h_diff = pdist2(c1',c2');
    val = h_diff / norm(double(Y));
    
end