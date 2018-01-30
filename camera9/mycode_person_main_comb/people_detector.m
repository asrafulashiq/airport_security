function [R_people] = people_detector_tracking(im_r, im_flow, R_people)

global scale;

im_g = rgb2gray(im_r);

%% background subtract
im_flow_g = rgb2gray(im_flow);
im_filtered = imgaussfilt(im_flow_g, 6);
im_filtered(im_filtered < R_people.threshold_img) = 0;

% close operation for the image
se = strel('disk',15);
im_closed = imclose(im_filtered,se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');
    
%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','BoundingBox', 'MajorAxisLength'); % extract parameters
body_prop = cpro_r1([cpro_r1.Area] > R_people.limit_init_area);
list_bbox = [];
for i = 1:size(body_prop, 1)
    body_prop(i).BoundingBox = body_prop(i).BoundingBox;
    list_bbox = [list_bbox; body_prop(i).Centroid];
    body_prop(i).Centroid = body_prop(i).Centroid';
end


%% detect

%%%%% TODO: exclude currently tracked person
del_index_of_body = [];

for i=1:numel(body_prop)
    for j=1:numel(R_people.people_array)      
        if norm(body_prop(i).Centroid - R_people.people_array{j}.Centroid) < R_people.min_allowed_dis
            del_index_of_body(end+1) = i;
            break;
        end       
    end
end
    
    
for i = 1:numel(body_prop)
    
    if find(del_index_of_body == i, 1)
        continue;
    end
    
    % check entrance
    bb = body_prop(i).BoundingBox;
    
    if body_prop(i).Centroid(2) < R_people.half_y  && ...
            body_prop(i).Centroid(1) < R_people.limit_exit_x1 && body_prop(i).Centroid(2) < R_people.limit_exit_y1
        
        limit_flag = false;
        centre_rec =  [  body_prop(i).BoundingBox(1)+body_prop(i).BoundingBox(3)/2  body_prop(i).BoundingBox(2)+body_prop(i).BoundingBox(4)/2  ];
        if body_prop(i).BoundingBox(3) > R_people.limit_max_width
            body_prop(i).BoundingBox(3) = R_people.limit_max_width;
            body_prop(i).BoundingBox(1) = centre_rec(1) - R_people.limit_max_width / 2;
            limit_flag = true;
        end
        if body_prop(i).BoundingBox(4) > R_people.limit_max_height
            body_prop(i).BoundingBox(4) = R_people.limit_max_height;
            body_prop(i).BoundingBox(2) = centre_rec(2) - R_people.limit_max_height / 2;
            limit_flag = true;
        end
        if limit_flag % area overloaded
            body_prop(i).BoundingBox = int32(body_prop(i).BoundingBox);
            body_prop(i).Area = sum(sum(imcrop(im_binary, body_prop(i).BoundingBox)));
        end
        
        %color_val = get_color_val(im_r, body_prop(i).BoundingBox, im_binary );
        %features = get_features(im_r, body_prop(i).BoundingBox, im_binary);
        Person = struct('Area', body_prop(i).Area, 'Centroid', ...
            body_prop(i).Centroid,'BoundingBox', body_prop(i).BoundingBox, ...
            'state', "unspec", 'label', R_people.label, 'tracker', [], ...
            'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0);
        R_people.label = R_people.label + 1;
        R_people.people_array{end+1} = Person;
        
    end
end


end