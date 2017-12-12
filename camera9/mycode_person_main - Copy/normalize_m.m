function X = normalize_m(X)

if size(X,2)==1
    
    X = (X - mean(X))/std(X);
    
else
    for i = 1:size(X,2)
       X(:,i) = normalize_m(X(:,i));
    end
    
end

end