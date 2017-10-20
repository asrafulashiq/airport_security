function [bbox_matched, min_val] = match_people_bbox(I, I_mask, img_struct, im_diff)

x_lim = 5;
y_lim = 5;
threshold = 0.7;
alpha = 2;

bbox = img_struct.BoundingBox;
ref_color_val = img_struct.color_val;

x1 = bbox(1) - x_lim;
x2 = bbox(1) + x_lim;
y1 = bbox(2) - y_lim;
y2 = bbox(2) + y_lim;

ind_array = zeros(x2-x1+1, y2-y1+1);

for x = x1:x2
    for y = y1:y2
        x_end  = min(x+bbox(3)-1, size(I,2));
        y_end = min(y+bbox(4)-1, size(I,1));
        width = x_end - x +1;
        height = y_end - y + 1;
        if x < 1 ||  y < 1 || width < threshold*bbox(3) || height < threshold*bbox(4)
            ind_array(x-x1+1,y-y1+1) = inf;
            continue;
        end
        
        % compare two images
        im_box = [x y width height];
        im_color_val = get_color_val(I, im_box,I_mask);
        if ~isempty(im_diff)
            ind_array(x-x1+1,y-y1+1) = norm(im_color_val - ref_color_val) - alpha * sum(sum(imcrop(im_diff, im_box))) ;
        else
            ind_array(x-x1+1,y-y1+1) = norm(im_color_val - ref_color_val);
        end
    end
end

[min_val,idx]=min(ind_array(:));
disp('min value :'); disp(min_val);
[x_min_index,y_min_index]=ind2sub(size(ind_array),idx);

x_min = x_min_index + x1 - 1;
y_min = y_min_index + y1 - 1;
x_end  = min(x_min+bbox(3)-1, size(I,2));
y_end = min(y_min+bbox(4)-1, size(I,1));
width = x_end - x_min + 1;
height = y_end - y_min + 1;

bbox_matched = [x_min y_min width height];

end