function bin_array =  match_template_signal(I, bin_array, loc_something)

obj_num = size(bin_array,2);
thr = 0.7;
% create rectangular tall pulse
r_tall = zeros(1,60);
r_tall(5:55) = 1;
r_tall = r_tall * 160;


% create rectangular wide pulse
r_wide = zeros(1,80);
r_wide(5:75) = 1;
r_wide = r_wide * 110;

%% 


if obj_num == 0
    
    
    
    % match
    coef_aray = [];
    loc_array = [];
    
    if isempty(loc_something)
        loc_something = [1 size(I,1)/2];
    end
    
    %loc_end = loc_something(2) - length(r_tall) + 1;
    
    if abs(loc_something(2) - loc_something(1)) <= thr * length(r_tall)
        return;
    end
    
    if abs(loc_something(2) - loc_something(1))> thr * length(r_tall) && loc_something(2)-loc_something(1) < length(r_tall)
        r_tall = ones(1, loc_something(2) - loc_something(1)+1 );
        r_tall(1:3) = 0; r_tall(end-2:end) = 0;
        r_tall = r_tall * 160;
    end
    
    
    for i = loc_something(1): ( loc_something(2) -  thr*length(r_tall) )
        I_d = calc_intens(I, [ i i+length(r_tall)-1 ]);
        coef = mean( r_tall .* I_d ) / norm(r_tall);
        
        if coef < 13
            continue;
        end
        coef_aray = [ coef_aray coef ];
        loc_array = [loc_array i];
        
    end
    %     for i = 1: size(I,1) / 2
    %         I_d = calc_intens(I, [ i i+length(r_wide)-1 ]);
    %         coef = mean( r_wide .* I_d ) / norm(r_wide) ;
    %         coef_aray = [ coef_aray coef ];
    %         loc_array = [loc_array i];
    %
    %     end
    
    if isempty(coef_aray)
        return;
    end
    
    [ max_val , max_index] = max(coef_aray);
    max_loc = loc_array(max_index);
    disp("max loc :"+max_loc);
    disp("max value :"+max_val)
    
    loc_end = max_loc + length(r_tall)-1;
    height = loc_end - max_loc + 1;
    T_ = I( max_loc: max_loc+length(r_tall)-1, : );
    Loc = [  size(I,2)/2  max_loc+length(r_tall)/2-1 ];
    
    %%% draw
    plot( max_loc:loc_end, r_tall );

    
    Bin = struct( ...
        'Area',size(T_,1)*size(T_,2), 'Centroid', Loc', ...
        'BoundingBox', [1 max_loc size(I,2) height ], ...
        'limit', [ max_loc loc_end ] ,...
        'image',I( max_loc : loc_end , : ), ...
        'belongs_to', -1, ...
        'label', -1 ...
        );
    
    bin_array{end+1} = Bin;
    
    %     figure(4); imshow(I(max_loc:max_loc+59,:));
    %
    %      x = [];
    
else
    
    loc_something = [ 1  size(I,1) ];
    
    for i = 1:obj_num
        
        lim = 20;
        loc_to_match = [ max([bin_array{i}.limit(1) - lim , loc_something(1)]) ...
            min( bin_array{i}.limit(2)+lim, loc_something(2) ) ];
        
        % match
        coef_aray = [];
        loc_array = [];
        
        if abs(loc_to_match(2) - loc_to_match(1))> thr * length(r_tall) && loc_to_match(2)-loc_to_match(1) < length(r_tall)
            r_tall = ones(1, loc_to_match(2) - loc_to_match(1)+1 );
            r_tall(1:3) = 0; r_tall(end-2:end) = 0;
            r_tall = r_tall * 160;
        end
        
        for j = loc_to_match(1): loc_to_match(2)- length(r_tall) + 1
            width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
            I_d = calc_intens(I, [ j j+length(r_tall)-1 ]);
            coef = mean( r_tall .* I_d ) / norm(r_tall);
            coef_aray = [ coef_aray coef ];
            loc_array = [loc_array j];
        end
        
        if isempty(coef_aray)
           1; 
        end
        
       
        
        [ max_val , max_index] = max(coef_aray);
        max_loc = loc_array(max_index);
        loc_end = max_loc + length(r_tall)-1;
        height = loc_end - max_loc + 1;
        T_ = I( max_loc: max_loc+length(r_tall)-1, : );
        Loc = [  size(I,2)/2  max_loc+length(r_tall)/2-1 ];
        
        %%% draw
        plot( max_loc:loc_end, r_tall );
        

        Bin = struct( ...
            'Area',size(T_,1)*size(T_,2), 'Centroid', Loc', ...
            'BoundingBox', [1 max_loc size(I,2) height ], ...
            'limit', [ max_loc loc_end ] ,...
            'image',I( max_loc : loc_end , : ), ...
            'belongs_to', bin_array{i}.belongs_to, ...
            'label', bin_array{i}.label ...
            );
        
        bin_array{i} = Bin;
        
        loc_something(2) = max_loc;
        
        
    end
    
    % search lowest y
    min_ = inf;
    for i = 1:size(bin_array,2)
        if bin_array{i}.limit(1) < min_
            min_ = bin_array{i}.BoundingBox(2);
        end
    end
    
    loc_2 = min_;
    if loc_2 > loc_something(1)
        
        bins = match_template_signal( I, {}, [loc_something(1) loc_2] );
        if ~isempty(bins)
            bin_array = {bin_array{:} bins{:}};
        end
    end
    
end


end