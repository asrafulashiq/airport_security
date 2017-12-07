function [bbox_, min_val, centroid] = match_people_bbox(I, I_mask, img_struct, im_flow)

x_lim = 5;
y_lim = 5;
threshold = 0.7;
alpha = 0.05;

bbox = img_struct.BoundingBox;
ref_color_val = img_struct.color_val;

flow_x = im_flow.Vx(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1);
flow_y = im_flow.Vy(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1);
flow_mag = im_flow.Magnitude(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1);

epsilon = 0.05;
flow_index = flow_mag > epsilon;

flow_x_mean = mean2(flow_x(flow_index));
flow_y_mean = mean2(flow_y(flow_index));

x_lim1 = int32(2);
x_lim2 = int32(2);
y_lim1 = int32(2);
y_lim2 = int32(2);

if flow_x_mean > 0
    x_lim2 = int32(flow_x_mean * 20);
else
    x_lim1 = int32(abs(flow_x_mean) * 20);
end

if flow_y_mean > 0
    y_lim2 = int32(flow_y_mean * 20);
else
    y_lim1 = int32(abs(flow_y_mean) * 20);
end

x1 = max(bbox(1) - x_lim1, 1);
x2 = min(bbox(1) + x_lim2, size(I,2));
y1 = max(bbox(2) - y_lim1, 1);
y2 = min(bbox(2) + y_lim2, size(I,1));


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
        if ~isempty(flow)
            flow_mag_box = im_flow.Magnitude(im_box(2):im_box(2)+im_box(4)-1, im_box(1):im_box(1)+im_box(3)-1);
            ind_array(x-x1+1,y-y1+1) = norm(im_color_val - ref_color_val) - alpha * sum(sum(flow_mag_box)) ;
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

centroid = ait_centroid(I_mask, bbox_matched);

if isempty(centroid)
    
    bbox_ = [];
    return 
end

x = max(centroid(1) - width / 2, 1);
y = max(centroid(2) - height / 2, 1);
x_ = min(centroid(1) + width / 2, size(I, 2));
y_ = min(centroid(2) + height / 2, size(I, 1));

wid = x_ - x + 1;
hei = y_ - y + 1;

bbox_ = [x y wid hei];

end