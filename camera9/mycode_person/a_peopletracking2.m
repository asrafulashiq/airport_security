function [people_seq, people_array] = a_peopletracking2(im_c,R_dropping,...
    R_belt,people_seq,people_array, bin_array)
%% region 1 extraction
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
thres_low = 0.4;
thres_up = 1.5;
min_allowed_dis = 200;
limit_area = 20000;
half_y = 1.9 * size(im_r,1) / 2;
limit_exit_y = 1100;
%% Region 1 background subtraction based on chromatic value

im_r_hsv = rgb2hsv(im_r);
im_p_hsv = rgb2hsv(R_dropping.im_r1_p);

im_fore = abs(im_r_hsv(:,:,2)-im_p_hsv(:,:,2)) + abs(im_p_hsv(:,:,2) - im_r_hsv(:,:,2));
im_fore = uint8(im_fore*255);

im_filtered = imgaussfilt(im_fore, 6);
im_filtered(im_filtered < 50) = 0;
% close operation for the image
se = strel('disk',10);
im_closed = imclose(im_filtered,se);

im_binary = logical(im_closed); %extract people region

%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'ConvexImage'); % extract parameters

body_prop = cpro_r1([cpro_r1.Area] > limit_area);
% for i = 1:size(cpro_r1, 1)
%     if cpro_r1(i).Area > limit_area
%         cpro_r1(i).Centroid = ait_centroid(im_binary, int32(cpro_r1(i).BoundingBox));
%         body_prop = [body_prop; cpro_r1(i)];
%         im_draw = insertShape(im_draw, 'Rectangle', int32(cpro_r1(i).BoundingBox), 'LineWidth', 10);
%     end
% end


list_bbox = [];
for i = 1:size(body_prop, 1)
    body_prop(i).BoundingBox = int32(body_prop(i).BoundingBox);
    list_bbox = [list_bbox; body_prop(i).BoundingBox];
end
%figure(2); imshow(im_draw);

%% track previous detection
exit_index_people_array = []; 
del_index_of_body = [];
if ~isempty(people_array)
    for i = 1:size(people_array,2)
        
        % detect exit
        if people_array{i}.Centroid(2) > limit_exit_y
            people_seq{end+1} = people_array{i};
            exit_index_people_array(end+1) = i;
            continue;
        end
        % calculate minimum distance body from people.Centroid to body(i).Centroid
        dist = pdist2(double(people_array{i}.BoundingBox(1:2)),double(list_bbox(:,1:2)));
        [min_dis, min_arg] = min(dist);
        %dist_sorted = sort(dist);
        %if dist_sorted()
        
        
        if body_prop(min_arg).Area > 1.3 * people_array{i}.Area && people_array{i}.state ~= "temp_disappear"
            % divide area and match
            bbox_matched = match_people_bbox(im_r, im_binary, body_prop(min_arg).BoundingBox, ...
                people_array{i});
            
            if ~isempty(bbox_matched)
                del_index_of_body = [del_index_of_body; min_arg];
                people_array{i}.Centroid =  ait_centroid(im_binary, bbox_matched);
                people_array{i}.BoundingBox = bbox_matched;
            end
            continue;
        end
        
        if min_dis > min_allowed_dis && size(people_array, 2) ~= size(body_prop, 1)
            %%% temporary gown away
            people_array{i}.state = "temp_disappear";
            continue;
        end
        
        del_index_of_body = [del_index_of_body; min_arg];
        people_array{i}.Centroid = body_prop(min_arg).Centroid;
        people_array{i}.Orientation = body_prop(min_arg).Orientation;
        people_array{i}.BoundingBox = int32(body_prop(min_arg).BoundingBox);
    end
end

% delete exit people
people_array(exit_index_people_array) = [];

%% initial detection
% Do detection & tracking first
im_draw = im_r;

for i = 1:size(body_prop, 1)
    
    if find(del_index_of_body == i, 1)
        continue;
    end
    
    % check exit
    if body_prop(i).Centroid(2) < half_y
            
        color_val = get_color_val(im_r, body_prop(i).BoundingBox, im_binary );
        Person = struct('Area', body_prop(i).Area, 'Centroid', body_prop(i).Centroid, ...
            'Orientation', body_prop(i).Orientation, 'BoundingBox', body_prop(i).BoundingBox, ...
            'state', "unspec", 'color_val', color_val);
        
        people_array{end+1} = Person;
        
    end
end

if size(people_array,2) > 2
    1;
end


im_draw = im_r;
for i = 1:size(people_array, 2)
    im_draw = insertShape(im_draw, 'Rectangle', people_array{i}.BoundingBox, 'LineWidth', 10);
    
end

figure(2); imshow(im_draw); 
drawnow;

end