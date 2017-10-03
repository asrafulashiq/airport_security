function loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b)

%%% loc to match
obj_num = size(bin_array,2);

if i > 1
    loc_end_match = min( bin_array{i}.limit(2)+lim, bin_array{i-1}.limit(1) );
end
if i < obj_num
    loc_strt_match = max(bin_array{i}.limit(1)-lim_b, bin_array{i+1}.limit(2)  );
end
if i==obj_num
    loc_strt_match = max(bin_array{i}.limit(1)-lim_b, loc_something(1) );
end
if i==1
    loc_end_match = min( bin_array{i}.limit(2)+lim, loc_something(2) );
end


loc_to_match = [loc_strt_match loc_end_match];



end