function Y = distfun(X, Z, thres)
    
    m = size(Z,1);
    Y = zeros(m,1);
    
    for i=1:m
       
       theta = X(3);
       rho = X(4);
        
       x = X(1) + rho * sind(theta);
       y = X(2) - rho * cosd(theta);
       
       Y(i) = norm([x,y] - Z(i,1:2));
       
       if Y(i) > thres
          Y(i) = inf; 
       end
        
    end

end