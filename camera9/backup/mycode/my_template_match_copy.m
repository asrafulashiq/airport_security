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

for i = loc_something(1) : ( loc_something(2) - thr * size(T,1) )
    
    if (i + size(T,1)-1 ) >= size(I_,1)
       break;
    end
    %last = min( (i + size(T,1)-1 ), loc_something(2) );
    s = ssim( I_( i: (i + size(T,1)-1 ) , :  ), T_ , 'Exponents', [1 0.1 1]);
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

%disp(max_val);

dim_y = loc_array(max_sim_index);

dim_y_2 = min( dim_y+size(T,1)-1, loc_something(2) );

if dim_y_2 < loc_something(2) && (loc_something(2) - dim_y_2) < 10 && ...
        mean2( I_(dim_y_2:loc_something(2),:)) > 100 

   dim_y_2 = loc_something(2); 
   dim_y = max(dim_y_2 - size(T,1)+1,1);
end

height = dim_y_2 - dim_y + 1;

Loc = [ size(I,2)/2  dim_y+height/2-1 ]; % centroid

Bin = struct( ...
    'Area',size(T,1)*size(T,2), 'Centroid', Loc, ...
    'BoundingBox', [1 dim_y size(T,2) dim_y_2 - dim_y + 1 ], ...
    'image',I( dim_y : dim_y_2 , 1:size(I,2) ), ...
    'belongs_to', -1, ...
    'label',-1 ...
    );


end