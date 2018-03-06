function [bbox_matched, min_val, centroid] = match_people_bbox(I, I_mask, img_struct, im_prev)

if nargin >=4 && isempty(im_prev)
    bbox_matched = [];
    centroid = [];
    min_val = [];
    return
end

x_lim = 5;
y_lim = 5;
threshold = 0.7;
alpha = 0.05;

bbox = img_struct.BoundingBox;
ref_color_val = img_struct.color_mat;

flow_mag = img_struct.flow_mag;
flow_angle = img_struct.flow_angle;

flow_x = flow_mag * sind(flow_angle);
flow_y = - flow_mag * cosd(flow_angle);


epsilon = 0.05;

x_lim1 = int32(2);
x_lim2 = int32(2);
y_lim1 = int32(2);
y_lim2 = int32(2);

mag_scale = 40;
if flow_x > 0
    x_lim2 = max(1,int32(flow_x * mag_scale));
else
    x_lim1 = max(int32(abs(flow_x) * mag_scale), 1);
end

if flow_y > 0
    y_lim2 = max(1,int32(flow_y * mag_scale));
else
    y_lim1 = max(1,int32(abs(flow_y) * mag_scale));
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
        %   [max_v, bb_new, ov] = BBS(im, bin_array{i}.BoundingBox, Iref, rect);
        % compare two images
        im_box = [x y width height];
        im_color_val = get_color_val(I, im_box,I_mask);
        if img_struct.color_count >= 40
            ind_array(x-x1+1,y-y1+1) = mahal(im_color_val, ref_color_val)  ;
        else
            ind_array(x-x1+1,y-y1+1) = norm(im_color_val - mean(ref_color_val))  ;
        end
%      pz = 15;
%      [max_v, ~, ~] = BBS(I, im_box, im_prev, bbox, pz);
%      ind_array(x-x1+1,y-y1+1) = -max_v;
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
    
    bbox_matched = [];
    return 
end

% x = max(centroid(1) - width / 2, 1);
% y = max(centroid(2) - height / 2, 1);
% x_ = min(centroid(1) + width / 2, size(I, 2));
% y_ = min(centroid(2) + height / 2, size(I, 1));
% 
% wid = x_ - x + 1;
% hei = y_ - y + 1;
% 
% bbox_ = [x y wid hei];

end