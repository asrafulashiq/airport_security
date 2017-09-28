function coef = calc_coef(r_tall, I_d, st)

    
    diff_ = zeros(1,length(r_tall));
    
    for i = 1:length(r_tall)
       if I_d(i) < r_tall(i)
            diff_(i) =   2*abs(I_d(i)-r_tall(i))  ;
       else
           diff_(i) =   abs(I_d(i)-r_tall(i))  ;
       end
    end
    
    coef = sum(abs( diff_ )) / length(r_tall);

    std_id = std(I_d,1);
    
    wt = 1;
    coef = coef + wt * abs(st - std_id);

end