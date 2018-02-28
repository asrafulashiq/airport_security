function v = feature_compare(f1, f2)

v = norm(f1 - f2) / (sqrt(norm(f1))* sqrt(norm(f2)));

end