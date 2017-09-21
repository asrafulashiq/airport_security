function bin_array = my_template_match_main(loc_something, I, bin_array, thr )

% t_struct = [];
% if target is smaller than template

obj_num = size(bin_array,2);

% if find_new == true
%     obj_num = 0;
% end

if obj_num == 0
    
    % detect new bin
    
    T = rgb2gray(imread('template1.jpg'));
    T = imadjust(T, [ 0; 0.6 ], [ 0.2; 0.8 ] );
    
    if abs(loc_something(2) - loc_something(1)) < thr * size(T,1)
        return;
    end
    if length(size(I))==3
        I = rgb2gray(I);
    end
    if length(size(T))==3
        T = rgb2gray(T);
    end
    
    width = min( size(T,2), size(I,2) );
    I_ = I(:, 1:width);
    T_ = T(:, 1:width);
    
    sim_array = [];
    loc_array = [];
    
    % height
    
    
    
    % determine target location
    
    
    x = [];
    
    if ( loc_something(2) + (1-thr)*size(T,1)) >= size(I,1)
       return; 
    end
    
    for i = loc_something(1) : ( loc_something(2) -  thr*size(T,1) )
        
        s = ssim( I_( i: (i + size(T,1)-1 ) , :  ), T_ );
        x = [x s];
        if s < 0.3
            continue;
        end
        sim_array = [ sim_array s ];
        loc_array = [loc_array i];
    end
    
    if isempty(sim_array)
        return;
    end
    
    [ ~ , max_sim_index] = max(sim_array);
    
    %disp(max_val);
    
    dim_y = loc_array(max_sim_index);
    dim_y_2 = min(dim_y+size(T,1)-1, loc_something(2) );
    
    
    
    if loc_something(2) - dim_y_2 < 15
        dim_y_2 = loc_something(2);
        dim_y = max(dim_y_2 - size(T,1)+1,1);
    end
    
    
    height = dim_y_2 - dim_y + 1;

    Loc = [ size(I,2)/2 dim_y+height/2-1 ]; % centroid
    
    
    Bin = struct( ...
        'Area',size(T,1)*size(T,2), 'Centroid', Loc, ...
        'BoundingBox', [1 dim_y size(T,2) dim_y_2 - dim_y + 1 ], ...
        'image',I( dim_y : dim_y_2 , 1:size(I,2) ), ...
        'belongs_to', -1, ...
        'label', -1 ...
        );
    
   
    bin_array{end+1} = Bin;
    
    
    % upper region
    loc_upper(1) = loc_something(1);
    loc_upper(2) = dim_y;
    
    if loc_upper(2) - loc_upper(1) > thr * size(T,1)
        
        bin_upper = my_template_match_main(loc_upper, I, {}, thr);
        
        if ~isempty(bin_upper)
            
            bin_array = {bin_array{:} bin_upper{:}};
            
        end
    end
    
    
    
else
    
    %     if obj_num > 1
    %         1;
    %     end
    
    
    
    for i = 1:obj_num
        
        T = bin_array{i}.image;
        
        if isempty(T)
            continue;
        end
        
        lim = 25;
        
        loc_to_match = [
            max( [ bin_array{i}.BoundingBox(2)-lim,loc_something(1) ])  ...
            min([ bin_array{i}.BoundingBox(2)+bin_array{i}.BoundingBox(4)+lim, loc_something(2) ]) %size(I,1)-lim )
            ];
        
        bin = my_template_match(loc_to_match, I, T, thr)  ;
        if ~isempty(bin)
            bin.belongs_to = bin_array{i}.belongs_to;
            bin.label = bin_array{i}.label;
            bin_array{i} = bin; % update bin information
            loc_something(2) = bin.BoundingBox(2);
        end
    end
    
    % search new bin
    % search lowest y
    min_ = inf;
    for i = 1:size(bin_array,2)
        if bin_array{i}.BoundingBox(2) < min_
            min_ = bin_array{i}.BoundingBox(2);
        end
    end
    
    loc_2 = min_;
    if loc_2 > loc_something(1)
        
        bins = my_template_match_main( [loc_something(1) loc_2], I, {}, thr );
        if ~isempty(bins)
            bin_array = {bin_array{:} bins{:}};
         
        end
    end
    
end

end