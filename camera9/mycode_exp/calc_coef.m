function coef = calc_coef(r_tall, I_d, st)


diff_ = zeros(1,length(r_tall));

for i = 1:length(r_tall)
    if I_d(i) < r_tall(i)
        diff_(i) =   2*abs(I_d(i)-r_tall(i)) ;  %%% change 3*
    else
        diff_(i) =   abs(I_d(i)-r_tall(i))  ;
    end
end

% peak
[~,locs] = findpeaks(I_d, 'MinPeakHeight', mean(I_d)*2,...
    'MinPeakProminence', mean(I_d));
if ~isempty(locs)
    loc_interest = find(pdist2(locs,locs)> 0.9 * length(r_tall) );
    if ~isempty(loc_interest )
        loc_interest = ceil(loc_interest/length(r_tall));
        if length(loc_interest) <= 3
            diff_(loc_interest) = -10;
        end
    end
end
coef = sum(abs( diff_ )) / length(r_tall);

std_id = std(I_d,1);

wt = 1;
coef = coef + wt * abs(st - std_id);

end