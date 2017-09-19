function t_struct = my_template_match(loc_something, I, T, thr )

t_struct = [];
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

for i = loc_something(1) : ( loc_something(2) - thr * size(T,1) )
    
    s = ssim( I_( i: (i + size(T,1)-1 ) , :  ), T_ );
    if s < 0.2
       continue; 
    end
    sim_array = [ sim_array s ]; 
    loc_array = [loc_array i];
end

 if isempty(sim_array)
     return; 
 end

[ max_val , max_sim_index] = max(sim_array);

%disp(max_val);

dim_y = loc_array(max_sim_index);
dim_y_2 = min( dim_y+size(T,1)-1, loc_something(2) );

Loc = [ size(I,2)/2  dim_y+size(T,1)/2-1 ]; % centroid

t_struct = struct('Area',size(T,1)*size(T,2), 'Centroid', Loc, ...
    'BoundingBox', [1 dim_y size(T,2) dim_y_2 - dim_y + 1 ] );

% 
% % upper region
% loc_upper(1) = loc_something(1);
% loc_upper(2) = dim_y;
% 
% if loc_upper(2) - loc_upper(1) > thr * size(T,1) 
%    
%    t_upper = htm_template(loc_upper, I, T, thr);
%    if ~isempty(t_upper)
%        t_struct = [t_upper; t_struct];
%    end
% end
% 
% 
% % lower region
% loc_lower(1) = dim_y + size(T,1) * thr;
% loc_lower(2) = dim_y + size(T,1) * thr;
% 
% if loc_lower(2) - loc_lower(1) > thr * size(T,1) 
%     
%    t_lower = htm_template(loc_lower, I, T, thr);
%    if ~isempty(t_lower)
%        t_struct = [t_struct; t_lower];
%    end
% end


end