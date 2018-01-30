function [R_people] = people_detector_tracking(im_r, im_flow, R_people)

global scale;

im_g = rgb2gray(im_r);

%% background subtract
im_flow_g = rgb2gray(im_flow);
im_flow_hsv = rgb2hsv(im_flow);

im_filtered = imgaussfilt(im_flow_g, 6);
im_tmp = im_filtered;
im_filtered(im_filtered < R_people.threshold_img) = 0;

% close operation for the image
se = strel('disk',15);
im_closed = imclose(im_filtered,se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');

im_flow_angle = im_flow_hsv(:,:,1) .* im_binary;
im_flow_val = im_flow_hsv(:,:,3) .* im_binary;
%im_flow_angle_degree = im_flow_angle / (180 / pi / 2);

% check bad flow
im_tmp(im_tmp < 5) = 0;
im_tmp = logical(im_tmp);
if sum(im_tmp(:)) > 40000
   return; 
end

%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','BoundingBox'); % extract parameters
body_prop = cpro_r1([cpro_r1.Area] > R_people.limit_area);

list_bbox = [];
for i = 1:size(body_prop, 1)

    body_prop(i).Centroid = body_prop(i).Centroid';
    
    % get angle
    angle_reg = imcrop(im_flow_angle, body_prop(i).BoundingBox);
    mag_reg = imcrop(im_flow_val, body_prop(i).BoundingBox);
    
    mean_angle = sum(angle_reg(:) .* mag_reg(:)) / sum(mag_reg(:));
    mean_angle = mean_angle * 180 * 2;
   
    body_prop(i).angle = mean_angle;
    
end


%% detect

%%%%% TODO: exclude currently tracked person
del_index_of_body = [];

for i=1:numel(body_prop)
    for j=1:numel(R_people.people_array)      
        if norm(body_prop(i).Centroid - R_people.people_array{j}.Centroid) < R_people.min_allowed_dis
            
            if body_prop(i).Area < 2*R_people.people_array{j}.Area && ...
                    body_prop(i).Area > 0.5 * R_people.people_array{j}.Area
                R_people.people_array{j}.Centroid = body_prop(i).Centroid;
                R_people.people_array{j}.Area = 0.5 * (body_prop(i).Area + R_people.people_array{j}.Area);
                R_people.people_array{j}.BoundingBox = body_prop(i).BoundingBox;
                R_people.people_array{j}.angle = body_prop(i).angle;
            else
               1; 
            end
            
            del_index_of_body(end+1) = i;
            break;
        end       
    end
end
    
for i = 1:numel(body_prop)
    
    if find(del_index_of_body == i, 1)
        continue;
    end
    
    if body_prop(i).Area < R_people.limit_init_area
       continue; 
    end
    
    % check entrance
    
    if body_prop(i).Centroid(2) < R_people.half_y  && ...
            body_prop(i).Centroid(1) < R_people.limit_init_x && ...
            body_prop(i).Centroid(2) < R_people.limit_init_y
        
        limit_flag = false;
        centre_rec =  [ body_prop(i).BoundingBox(1) + body_prop(i).BoundingBox(3)/2 ...
            body_prop(i).BoundingBox(2) + body_prop(i).BoundingBox(4)/2];
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
        
        Person = struct('Area', body_prop(i).Area, 'Centroid', ...
            body_prop(i).Centroid,'BoundingBox', body_prop(i).BoundingBox, ...
            'state', "unspec", 'label', R_people.label, 'counter', 1, ...
            'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0, ...
            'angle', body_prop(i).angle);
        Person.prev_angle = zeros(1,5);
        R_people.label = R_people.label + 1;
        R_people.people_array{end+1} = Person;
        
    end
end

% check exit
del_exit = [];
for i=1:numel(R_people.people_array)
    person = R_people.people_array{i};
    
    person.prev_angle()
    
    if person.Centroid(1) > R_people.limit_exit_x && person.Centroid(2) >  R_people.limit_exit_y
        del_exit(end+1) = i;
    end
    
    R_people.people_array{i}.counter = R_people.people_array{i}.counter + 1;
    
end

R_people.people_array(del_exit) = [];

end