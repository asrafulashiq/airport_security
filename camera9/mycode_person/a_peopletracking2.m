function [people_seq, people_array, R_dropping] = a_peopletracking2(im_c,R_dropping,...
    R_belt,people_seq,people_array, bin_array)
%% region 1 extraction
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
thres_low = 0.4;
thres_up = 1.5;
min_allowed_dis = 200;
limit_area = 20000;
limit_init_area = 30000;
limit_max_width = 400;
limit_max_height = 400;
half_y = 1.6 * size(im_r,1) / 2;
limit_exit_y1 = 1050;
limit_exit_x1 = 300;
limit_exit_y2 = 800;
limit_exit_x2 = 300;
threshold_img = 50;
%% Region 1 background subtraction based on chromatic value

im_r_hsv = rgb2hsv(im_r);
im_p_hsv = rgb2hsv(R_dropping.im_r1_p);

im_fore = abs(im_r_hsv(:,:,2)-im_p_hsv(:,:,2)) + abs(im_p_hsv(:,:,2) - im_r_hsv(:,:,2));
im_fore = uint8(im_fore*255);

im_filtered = imgaussfilt(im_fore, 6);
im_filtered(im_filtered < threshold_img) = 0;
% close operation for the image
se = strel('disk',10);
im_closed = imclose(im_filtered,se);
%im_eroded = imerode(im_closed, se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');
%im_binary = logical(im_eroded);

%% calculate difference image
im_diff = [];
if ~isempty(R_dropping.prev_body)
    
    im_diff = abs(double(rgb2gray(im_r)) - double(rgb2gray(R_dropping.prev_body)));
    im_diff(norm(im_diff) < 30) = 0;
    im_diff = double(im_diff);
    %im_diff = abs(im_binary - R_dropping.prev_body);
    im_diff = mat2gray(im_diff);
end

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
if ~isempty(people_array) && ~isempty(list_bbox)
    for i = 1:size(people_array,2)
        
        % detect exit
        if ( people_array{i}.Centroid(2) > limit_exit_y1 && people_array{i}.Centroid(1) > limit_exit_x1 ) || ...
               ( people_array{i}.Centroid(2) > limit_exit_y2 && people_array{i}.Centroid(1) > limit_exit_x2 )
                 % && people_array{i}.Centroid(2) > half_y)
            people_seq{end+1} = people_array{i};
            exit_index_people_array(end+1) = i;
            disp('exit......');
            continue;
        end
        % calculate minimum distance body_prop(i) from people.Centroid to body_prop(i)(i).Centroid
        dist = pdist2(double(people_array{i}.BoundingBox(1:2)),double(list_bbox(:,1:2)));
        [min_dis, min_arg] = min(dist);
        %dist_sorted = sort(dist);
        %if dist_sorted()
        
        
        if body_prop(min_arg).BoundingBox(3)>limit_max_width || body_prop(min_arg).BoundingBox(4)>limit_max_height ...
                %&& people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * people_array{i}.Area
            % divide area and match
            [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, people_array{i}, im_diff);
            
            if ~isempty(bbox_matched)
                del_index_of_body = [del_index_of_body; min_arg];
                people_array{i}.Centroid = centroid; %ait_centroid(im_binary, bbox_matched);
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
        people_array{i}.BoundingBox = body_prop(min_arg).BoundingBox;
    end
end

% delete exit people
people_array(exit_index_people_array) = [];

% check if area is too big

for i = 1:size(people_array, 2)
    if people_array{i}.BoundingBox(3)>limit_max_width || people_array{i}.BoundingBox(4)>limit_max_height
        centre_rec =  [  people_array{i}.BoundingBox(1)+people_array{i}.BoundingBox(3)/2 ...
            people_array{i}.BoundingBox(2)+people_array{i}.BoundingBox(4)/2  ];
        
        if people_array{i}.BoundingBox(3) > limit_max_width
            people_array{i}.BoundingBox(3) = limit_max_width;
            people_array{i}.BoundingBox(1) = centre_rec(1) - limit_max_width / 2;
        end
        
        if people_array{i}.BoundingBox(4) > limit_max_height
            people_array{i}.BoundingBox(4) = limit_max_height;
            people_array{i}.BoundingBox(2) = centre_rec(2) - limit_max_height / 2;
        end
        people_array{i}.BoundingBox = int32(people_array{i}.BoundingBox);
        people_array{i}.Area = sum(sum(imcrop(im_binary, people_array{i}.BoundingBox)));
        %color_val = get_color_val(im_r, people_array{i}.BoundingBox, im_binary );
    end
end

%% initial detection
% Do detection & tracking first
im_draw = im_r;

for i = 1:size(body_prop, 1)
    
    if find(del_index_of_body == i, 1)
        continue;
    end
    
    % check entrance
    if body_prop(i).Centroid(2) < half_y && body_prop(i).Area > limit_init_area
        
        limit_flag = false;
        centre_rec =  [  body_prop(i).BoundingBox(1)+body_prop(i).BoundingBox(3)/2  body_prop(i).BoundingBox(2)+body_prop(i).BoundingBox(4)/2  ];
        if body_prop(i).BoundingBox(3) > limit_max_width
            body_prop(i).BoundingBox(3) = limit_max_width;
            body_prop(i).BoundingBox(1) = centre_rec(1) - limit_max_width / 2;
            limit_flag = true;
        end
        if body_prop(i).BoundingBox(4) > limit_max_height
            body_prop(i).BoundingBox(4) = limit_max_height;
            body_prop(i).BoundingBox(2) = centre_rec(2) - limit_max_height / 2;
            limit_flag = true;
        end
        if limit_flag % area overloaded
            body_prop(i).BoundingBox = int32(body_prop(i).BoundingBox);
            body_prop(i).Area = sum(sum(imcrop(im_binary, body_prop(i).BoundingBox)));
        end
        color_val = get_color_val(im_r, body_prop(i).BoundingBox, im_binary );
        Person = struct('Area', body_prop(i).Area, 'Centroid', body_prop(i).Centroid, ...
            'Orientation', body_prop(i).Orientation, 'BoundingBox', body_prop(i).BoundingBox, ...
            'state', "unspec", 'color_val', color_val, 'label', R_dropping.label);
        R_dropping.label = R_dropping.label + 1;
        people_array{end+1} = Person;
        
    end
end

if size(people_array,2) > 2
    1;
end


im_draw = im_r;
for i = 1:size(people_array, 2)
    im_draw = insertShape(im_draw, 'Rectangle', people_array{i}.BoundingBox, 'LineWidth', 10);
    im_draw = insertShape(im_draw, 'FilledCircle', [people_array{i}.Centroid 20] );
    
end

figure(2); imshow(im_draw);


%% some test image
if ~isempty(R_dropping.prev_body)
    
    %im_diff = (abs(double(im_r_hsv(:,:,2)) - double(R_dropping.prev_body)));
    
    %figure(3); imshow(im_diff,[]);
end
% R_dropping.prev_body = im_r_hsv(:,:,2);
%R_dropping.prev_body = im_binary;
R_dropping.prev_body = im_r;

%figure(3);imshow(im_binary);

drawnow;

end