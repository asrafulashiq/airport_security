function Bin = my_template_match(loc_something, I, T, thr )

Bin = [];
% if target is smaller than template
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

% for i = loc_something(1) : ( loc_something(2) - thr * size(T,1) )
%     
%     if (i + size(T,1)-1 ) >= size(I_,1)
%        break;
%     end
%     %last = min( (i + size(T,1)-1 ), loc_something(2) );
%     image = I_( int64(i: (i + size(T,1)-1 )) , 10: end );
%     s = ssim( image , T_(:,10:end) , 'Exponents', [1 0.3 1], 'Radius',5);
%     %s = hist_compare(image, T_);
%     
%     if s < 0.2
%         continue;
%     end
%     sim_array = [ sim_array s ];
%     loc_array = [loc_array i];
% end

for i = loc_something(2):-1:(loc_something(1)+thr*size(T,1))  %loc_something(1) : ( loc_something(2) - thr * size(T,1) )
    
    if (i - size(T,1)+1 ) < loc_something(1)
       break;
    end
    %last = min( (i + size(T,1)-1 ), loc_something(2) );
    image = I_( int64( ( i-size(T,1)+1 ) :i ) , 10: end );
    s = ssim( image , T_(:,10:end) , 'Exponents', [1 0.3 1], 'Radius',5);
    %s = hist_compare(image, T_);
    
    if s < 0.2
        continue;
    end
    sim_array = [ sim_array s ];
    loc_array = [loc_array i];
end

if isempty(sim_array)
    return;
end

[ ~ , max_sim_index] = max(sim_array);


dim_y_2 = loc_array(max_sim_index);

dim_y = max( dim_y_2-size(T,1)+1, loc_something(1) );


%disp(max_val);

% dim_y = loc_array(max_sim_index);
% 
% dim_y_2 = min( dim_y+size(T,1)-1, loc_something(2) );
% 
% if dim_y_2 < loc_something(2) && (loc_something(2) - dim_y_2) < 10 && ...
%         mean2( I( int64(dim_y_2:loc_something(2)),:)) > 100 
% 
%    dim_y_2 = loc_something(2)  ; 
%    dim_y = max(dim_y_2 - size(T,1)+1,1);
% end

% if loc_something(1) < dim_y && (dim_y - loc_something(1)) < 10 && ...
%         mean2( I( loc_something(1):dim_y, :) )> 100
%     
%    dim_y = loc_something(1); 
% end

height = dim_y_2 - dim_y + 1;

 Loc = [ size(I,2)/2  dim_y+height/2-1 ]; % centroid
 
% if height > size(T,1)
%     
%     diff_h = height - size(T,1);
%     x = 1; dim_y = dim_y + int64(diff_h/2);
%     width = size(T,2); height_ = dim_y_2 - dim_y + 1;   
% else
%     x = 1; 
%     width = size(T,2); height_ = dim_y_2 - dim_y + 1;
% end

Bin = struct( ...
    'Area',size(T,1) * size(T,2), 'Centroid', Loc, ...
    'BoundingBox', [1 dim_y width height ], ...
    'image',I( int64(dim_y : dim_y_2) , 1:size(I,2) ), ...
    'belongs_to', -1, ...
    'label',-1 ...
    );


end