function [t_struct,template] = my_template_match_main(loc_something, I, template, thr )

t_struct = [];
% if target is smaller than template

obj_num = size(template,2);

% if find_new == true
%     obj_num = 0;
% end

if obj_num == 0
    T = rgb2gray(imread('template1.jpg'));
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
    
    % determine target location
    
    
    
    for i = loc_something(1) : ( loc_something(2) - thr* size(T,1) )
        
        s = ssim( I_( i: (i + size(T,1)-1 ) , :  ), T_ );
        if s < 0.22
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
    dim_y_2 = min(dim_y+size(T,1), loc_something(2) );
%   Loc = [ size(I,2)/2 dim_y+size(T,1)/2 ]; % centroid
    
    Loc = [ size(I,2)/2 dim_y+(dim_y_2 - dim_y)/2-1 ]; % centroid
    k = 1;
    
%     for i = 1:size(template,1)
%        if Loc(2) < template(i,2) && Loc(2) > template(i,1)
%           k = 0;
%           break;
%        end
%     end
    
    if k==1
        t_struct = struct('Area',size(T,1)*size(T,2), 'Centroid', Loc, ...
            'BoundingBox', [1 dim_y size(T,2) dim_y_2 - dim_y + 1 ] );
        template{end+1} = struct( ...
            'image',I( dim_y : dim_y_2 , 1:size(I,2) ), ...
            'BoundingBox', [1 dim_y size(T,2) dim_y_2 - dim_y + 1 ] ...
            ) ;
    end
     
    % upper region
    loc_upper(1) = loc_something(1);
    loc_upper(2) = dim_y;
    
    if loc_upper(2) - loc_upper(1) > thr * size(T,1)
        
        [t_upper, temp] = my_template_match_main(loc_upper, I, {}, thr);
        if ~isempty(t_upper)
            t_struct = [t_upper; t_struct];
            template{end+1} = temp;
%             struct( ...
%             'image', I( t_upper.BoundingBox(2) : ( t_upper.BoundingBox(2)+t_upper.BoundingBox(4)-1 ), 1:size(I,2) ) , ...
%             'BoundingBox', [1 t_upper.BoundingBox(2) size(T,2) t_upper.BoundingBox(4) ] ...
%             ) ;       
            
        end
    end
    
    
    % lower region
%     loc_lower(1) = dim_y + size(T,1) * thr;
%     loc_lower(2) = loc_something(2);
%     
%     if loc_lower(2) - loc_lower(1) > thr * size(T,1)
%         
%         t_lower = my_template_match(loc_lower, I, T, thr);
%         if ~isempty(t_lower)
%             t_struct = [t_struct; t_lower];
%              template{end+1} = I( t_lower.BoundingBox(2) : ( t_lower.BoundingBox(2)+t_lower.BoundingBox(4)-1 ), 1:size(I,2) ) ;
%         end
%     end
      
else
    
    if obj_num > 1
       1; 
    end
    
    for i = 1:obj_num
        
        T = template{i}.image;
        if isempty(T)
           continue; 
        end
        
        lim = 25;
        
        loc_to_match = [
            max( template{i}.BoundingBox(2)-lim,1)  ...
            min( template{i}.BoundingBox(2)+template{i}.BoundingBox(4)+lim, size(I,1)-lim )
        ];
        
        t_s = my_template_match(loc_to_match, I, T, thr)  ;
        if ~isempty(t_s)
            T = I( t_s.BoundingBox(2) : ( t_s.BoundingBox(2)+t_s.BoundingBox(4)-1 ), 1:size(I,2) );
            template{i}.image = T;
            template{i}.BoundingBox = t_s.BoundingBox;
        end
        t_struct = [t_struct; t_s];
    end
    
    % search new bin
    % search lowest y
    min_ = inf;
    for i = 1:size(t_struct,1)
        if t_struct(i).BoundingBox(2) < min_
            min_ = t_struct(i).BoundingBox(2);
        end
    end
    
    loc_2 = min_;
    if loc_2 > loc_something(1)
       [t_s, temp] = my_template_match_main( [loc_something(1) loc_2], I, {}, thr );
       if ~isempty(t_s)
          t_struct = [t_struct; t_s];
          for i = size(temp,2)
             if ~isempty(temp{i})
                template{end+1} = temp{i}; 
             end
          end
       end
    end
    
end

end