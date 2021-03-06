function t_struct = htm_template(loc_something, I, T, thr )

t_struct = [];
% if target is smaller than template
if abs(loc_something(2) - loc_something(1)) < thr * size(T,1)    
    return;
end

htm=vision.TemplateMatcher('ROIInputPort',true) ;

if length(size(I))==3
    I = rgb2gray(I);
end
if length(size(T))==3
    T = rgb2gray(T);
end

% detect first object
a = loc_something(1); b = loc_something(end);
x = 1; y = a;
wid = size(I,2);
hei = b - a + 1;

Loc = step(htm,I,T,[x y wid hei]);
if rem( size(T,1),2 ) == 0
    dim_y = Loc(2) - size(T,1) / 2 + 1;
else
    dim_y = ceil(Loc(2) - size(T,1) / 2 );
end

width = min( size(T,2), size(I,2) );
I_ = I(:, 1:width);
T_ = T(:, 1:width);

similarity_index = ssim(I_(dim_y:(dim_y+size(T_,1)-1),:),T_);
disp(similarity_index);

if similarity_index < .22
   return; 
end

t_struct = struct('Area',size(T,1)*size(T,2), 'Centroid', Loc, ...
    'BoundingBox', [1 dim_y size(T,2) size(T,1)] );

t_struct = [t_struct];

% upper region
loc_upper(1) = loc_something(1);
loc_upper(2) = dim_y;

if loc_upper(2) - loc_upper(1) > thr * size(T,1) 
   
   t_upper = htm_template(loc_upper, I, T, thr);
   if ~isempty(t_upper)
       t_struct = [t_upper; t_struct];
   end
end


% lower region
loc_lower(1) = dim_y + size(T,1) * thr;
loc_lower(2) = dim_y + size(T,1) * thr;

if loc_lower(2) - loc_lower(1) > thr * size(T,1) 
    
   t_lower = htm_template(loc_lower, I, T, thr);
   if ~isempty(t_lower)
       t_struct = [t_struct; t_lower];
   end
end


end