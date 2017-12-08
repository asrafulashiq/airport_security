
function coef = calc_coef_w(r_tall, I_d )
    coef = sum(abs( r_tall - I_d )) / length(r_tall);
end