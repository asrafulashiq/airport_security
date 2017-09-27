function coef = calc_coef(r_tall, I_d, st)
    coef = sum(abs( r_tall - I_d )) / length(r_tall);
    std_id = std(I_d,1);
    
    wt = 2;
    coef = coef + wt * abs(st - std_id);

end