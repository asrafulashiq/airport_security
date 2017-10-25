function [people_seq, people_array, R_dropping] = a_peopletracking2(im_c,R_dropping,...
    R_belt,people_seq,people_array, bin_array)
%% region 1 extraction
global scale;
global debug_people;
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
thres_low = 0.4;
thres_up = 1.5;
min_allowed_dis = 200 * scale;
limit_area = 14000 * scale^2;
limit_init_area = 35000 *  scale^2;
limit_max_width = 420 *  scale;
limit_max_height = 420 * scale;
half_y = 1.6 * size(im_r,1) / 2;
limit_exit_y1 = 1070 * scale;
limit_exit_x1 = 250 * scale;
limit_exit_y2 = 600 * scale;
limit_exit_x2 = 210 * scale;
threshold_img = 50 ;

critical_exit_x = 0.5 * size(im_r, 2);
critical_exit_y = 0.4 * size(im_r, 1);

exit_vanishing_area = 30000 * scale^2;
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

cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'MajorAxisLength'); % extract parameters

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
    list_bbox = [list_bbox; body_prop(i).Centroid];
    body_prop(i).Centroid = body_prop(i).Centroid';
    
end
%figure(2); imshow(im_draw);

%% track previous detection
exit_index_people_array = [];
del_index_of_body = [];
if ~isempty(people_array) && ~isempty(list_bbox)
    
    for i = 1:size(people_array,2)
        % detect exit
        if ( people_array{i}.Centroid(2) > limit_exit_y1 && people_array{i}.Centroid(1) > limit_exit_x1 ) || ...
                ( people_array{i}.Centroid(2) > limit_exit_y2 && people_array{i}.Centroid(1) > limit_exit_x2 && ...
                people_array{i}.Area < exit_vanishing_area && people_array{i}.critical_del > 10)
            % && people_array{i}.Centroid(2) > half_y)
            people_seq{end+1} = people_array{i};
            exit_index_people_array(end+1) = i;
            disp('exit......');
            continue;
        end
    end
    
    if people_array{i}.Centroid(1) > critical_exit_x && people_array{i}.Centroid(2) > critical_exit_y
       
        if isempty(people_array{i}.critical_del) 
            people_array{i}.prev_centroid = people_array{i}.Centroid;
            people_array{i}.critical_del = 0;
        else
            if people_array{i}.Centroid(1) > people_array{i}.prev_centroid(1)
               people_array{i}.critical_del = people_array{i}.critical_del + 1;
            else
                people_array{i}.critical_del = people_array{i}.critical_del - 1;
            end
        end
    else
        if ~isempty(people_array{i}.critical_del)
            people_array{i}.critical_del = [];
        end
    end
    
    people_array(exit_index_people_array) = [];
    people_array_struct = [people_array{:}];
    % determine minimum distance
    min_dis_vector = [];
    for i = 1:size(people_array,2)
        dist = pdist2(double(people_array{i}.Centroid'),double(list_bbox));
        [min_dis, min_arg] = min(dist);
        min_dis_vector = [min_dis_vector; min_dis min_arg];
    end
    
    % resolve conflict
    vect = unique(min_dis_vector(:,2),'stable');
    count_el = zeros(1,length(vect));
    for tmp_i = 1:size(vect)
        count_el(tmp_i) = sum( min_dis_vector(:,2) == vect(tmp_i) );
    end
    
    for i = 1:length(vect)
        if count_el(i) == 1
            % only one bounding box match
            prev_index = min_dis_vector(:,2) == vect(i);
            min_arg = vect(i);
            
            if body_prop(min_arg).BoundingBox(3)>limit_max_width || body_prop(min_arg).BoundingBox(4)>limit_max_height ...
                    %&& people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * people_array{i}.Area
                % divide area and match
                [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, people_array{prev_index}, im_diff);
                
                if ~isempty(bbox_matched)
                    del_index_of_body = [del_index_of_body; min_arg];
                    people_array{prev_index}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                    people_array{prev_index}.BoundingBox = bbox_matched;
                end
                continue;
            end
            
            del_index_of_body = [del_index_of_body; min_arg];
            people_array{prev_index}.Centroid = body_prop(min_arg).Centroid;
            people_array{prev_index}.Orientation = body_prop(min_arg).Orientation;
            people_array{prev_index}.BoundingBox = body_prop(min_arg).BoundingBox;
            people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
            people_array{prev_index}.Area = body_prop(min_arg).Area;
        else
            % more than one bounding box matched
            %
            x_c = body_prop(vect(i)).Centroid(1); 
            y_c = body_prop(vect(i)).Centroid(2);
            L = body_prop(vect(i)).MajorAxisLength;
            theta = -deg2rad(body_prop(vect(i)).Orientation);
            if theta < 0
               theta = theta + pi; 
            end
            
            prev_ind = find(min_dis_vector(:,2) == vect(i));
            prev_people = [people_array_struct(prev_ind)];
            list_centroid = [prev_people.Centroid];
            [~,I] = sort(list_centroid(2,:), 'descend');
            
            kappa = [prev_people.Area] / sum([prev_people.Area]);
            
            offset = 0;
            for j = 1:size(prev_ind)
                index = I(j);
                r = L / 2 * (1 - kappa(index)) - offset;
                xtmp = x_c + r * cos(theta);
                ytmp = y_c + r * sin(theta);
                
                cent = [xtmp ytmp]';
                people_array{prev_ind(index)}.Centroid = cent;
                
                % update bounding box
                width = people_array{prev_ind(index)}.BoundingBox(3);
                height = people_array{prev_ind(index)}.BoundingBox(4);
                x = max(cent(1) - width / 2, 1);
                y = max(cent(2) - height / 2, 1);
                x_ = min(cent(1) + width / 2, size(im_r, 2));
                y_ = min(cent(2) + height / 2, size(im_r, 1));

                wid = x_ - x + 1;
                hei = y_ - y + 1;

                bbox = [x y wid hei];
                people_array{prev_ind(index)}.BoundingBox = bbox;
                
                offset = offset + L * kappa(index);
            end
            del_index_of_body = [del_index_of_body; vect(i)];
            
        end
    end
    
    %     for i = 1:size(people_array,2)
    %
    %
    %         % calculate minimum distance body_prop(i) from people.Centroid to body_prop(i)(i).Centroid
    %
    %         %dist_sorted = sort(dist);
    %         %if dist_sorted()
    %
    %
    %         if body_prop(min_arg).BoundingBox(3)>limit_max_width || body_prop(min_arg).BoundingBox(4)>limit_max_height ...
    %                 %&& people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * people_array{i}.Area
    %             % divide area and match
    %             [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, people_array{i}, im_diff);
    %
    %             if ~isempty(bbox_matched)
    %                 del_index_of_body = [del_index_of_body; min_arg];
    %                 people_array{i}.Centroid = centroid; %ait_centroid(im_binary, bbox_matched);
    %                 people_array{i}.BoundingBox = bbox_matched;
    %             end
    %             continue;
    %         end
    %
    %         if min_dis > min_allowed_dis && size(people_array, 2) ~= size(body_prop, 1)
    %             %%% temporary gown away
    %             people_array{i}.state = "temp_disappear";
    %             continue;
    %         end
    %
    %         del_index_of_body = [del_index_of_body; min_arg];
    %         people_array{i}.Centroid = body_prop(min_arg).Centroid;
    %         people_array{i}.Orientation = body_prop(min_arg).Orientation;
    %         people_array{i}.BoundingBox = body_prop(min_arg).BoundingBox;
    %     end
end

% delete exit people

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
    if body_prop(i).Centroid(2) < half_y && body_prop(i).Area > limit_init_area && ...
            body_prop(i).Centroid(1) < limit_exit_x1 && body_prop(i).Centroid(2) < limit_exit_y1 
        
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
            'state', "unspec", 'color_val', color_val, 'label', R_dropping.label, ...
            'critical_del', [], 'prev_centroid',[]);
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
    im_draw = insertShape(im_draw, 'FilledCircle', [people_array{i}.Centroid' 20] );
    
end

%figure(2); imshow(im_draw);

% sort people 
% if ~isempty(people_array)
%     people_array_struct = [people_array{:}];
%     list_centroid = [people_array_struct.Centroid];
%     [~,I] = sort(list_centroid(2,:), 'descend');
%     people_array = {people_array{I}};
% end
%% some test image
if ~isempty(R_dropping.prev_body) && debug_people
    figure(2); imshow(im_draw);
    
    im_diff = uint8(abs(double(im_r(:,:,2)) - double(R_dropping.prev_body)));
    
    figure(3); imshow(rgb2gray(im_diff),[]);
    figure(4);imshow(im_binary);
    drawnow;
    
end 
% R_dropping.prev_body = im_r_hsv(:,:,2);
%R_dropping.prev_body = im_binary;
R_dropping.prev_body = im_r;


end