function [people_seq, people_array, R_dropping] = a_peopletracking2(im_c,R_dropping,...
    R_belt,people_seq,people_array, bin_array, currentTime)
%% region 1 extraction
global scale;
global debug_people;
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
min_allowed_dis = 200 * scale;
limit_area = 14000 * scale^2;
limit_init_area = 35000 *  scale^2;
limit_max_width = 450 *  scale;
limit_max_height = 450 * scale;
half_y = 190 * 2 * scale;%0.3 * size(im_r,1) / 2;
limit_exit_y1 = 1070 * scale;
limit_exit_x1 = 250 * scale;
limit_exit_y2 = 600 * scale;
limit_exit_x2 = 210 * scale;
threshold_img = 60;

im_g = rgb2gray(im_r);
flow = estimateFlow(R_dropping.optic_flow, im_g);
R_dropping.flow = flow;


if debug_people
    half_y = 1.6 * size(im_r,1) / 2;
end

thres_critical_del = 6;
thres_temp_count_low = 15;
thres_temp_count_high = 100;

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
se = strel('disk',15);
im_closed = imclose(im_filtered,se);
%im_eroded = imerode(im_closed, se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');
%im_binary = logical(im_eroded);

%% calculate difference image
% im_diff = [];
%
% if ~isempty(R_dropping.prev_body)
%     im_diff = abs(double(rgb2gray(im_r)) - double(rgb2gray(R_dropping.prev_body)));
%     im_diff(norm(im_diff) < 30) = 0;
%     im_diff = double(im_diff);
%     im_diff = mat2gray(im_diff);
% end

%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'MajorAxisLength'); % extract parameters
body_prop = cpro_r1([cpro_r1.Area] > limit_area);
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
        % detect exit from camera 9
        if ( people_array{i}.Centroid(2) > limit_exit_y1 && people_array{i}.Centroid(1) > limit_exit_x1 ) || ...
                ( people_array{i}.Centroid(2) > limit_exit_y2 && people_array{i}.Centroid(1) > limit_exit_x2 && ...
                (~isempty(people_array) && people_array{i}.critical_del >= thres_critical_del)) % people_array{i}.Area < exit_vanishing_area
            
            % && people_array{i}.Centroid(2) > half_y)
            %people_seq{end+1} = people_array{i};
            people_array{i}.temp_count = 0;
            R_dropping.exit_from_9{end+1} = people_array{i};
            exit_index_people_array(end+1) = i;
            disp('exit......');
            continue;
        end
        if people_array{i}.state=="temporary_vanishing"
            if (people_array{i}.Centroid(1) > limit_exit_x1 && people_array{i}.temp_count > thres_temp_count_low) || ...
                    (people_array{i}.Centroid(1) > limit_exit_x2 && people_array{i}.temp_count > thres_temp_count_high) ...
                    || (people_array{i}.temp_count > 400)
                people_seq{end+1} = people_array{i};
                exit_index_people_array(end+1) = i;
                disp('exit......');
                continue;
            end
        end
        
        if people_array{i}.Centroid(1) > critical_exit_x && people_array{i}.Centroid(2) > critical_exit_y
            
            if (people_array{i}.critical_del) == -1000
                people_array{i}.prev_centroid = people_array{i}.Centroid(1);
                people_array{i}.critical_del = 0;
            else
                if people_array{i}.Centroid(1) > people_array{i}.prev_centroid
                    people_array{i}.critical_del = people_array{i}.critical_del + 1;
                else
                    people_array{i}.critical_del = people_array{i}.critical_del - 1;
                end
            end
        else
            if (people_array{i}.critical_del) ~= -1000
                people_array{i}.critical_del = -1000;
            end
        end
    end
    
    people_array(exit_index_people_array) = [];
    people_array_struct = [people_array{:}];
    % determine minimum distance
    min_dis_vector = [];
    if ~isempty(people_array)
        
        dist = pdist2(double([people_array_struct.Centroid]'), double(list_bbox));
        for i = 1:size(people_array,2)
            dist_ = dist(i,:);
            [min_dis, min_arg] = min(dist_);
            
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
                
                if body_prop(min_arg).BoundingBox(3)>limit_max_width || body_prop(min_arg).BoundingBox(4)>limit_max_height
                    %&& people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * people_array{i}.Area
                    % divide area and match
                    [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, people_array{prev_index}, flow);
                    
                    if ~isempty(bbox_matched)
                        del_index_of_body = [del_index_of_body; min_arg];
                        people_array{prev_index}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                        people_array{prev_index}.BoundingBox = bbox_matched;
                        people_array{prev_index}.temp_count = 0;
                    end
                    continue;
                end
                
                if dist(prev_index, min_arg) > min_allowed_dis || body_prop(min_arg).Area <  0.3 * people_array{prev_index}.Area
                    people_array{prev_index}.state = "temporary_vanishing";
                    people_array{prev_index}.temp_count = people_array{prev_index}.temp_count+1;
                    continue;
                end
                
                people_array{prev_index}.Centroid = body_prop(min_arg).Centroid;
                del_index_of_body = [del_index_of_body; min_arg];
                
                people_array{prev_index}.BoundingBox = body_prop(min_arg).BoundingBox;
                people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                people_array{prev_index}.Area = body_prop(min_arg).Area;
                
                % check second minimum value
                if length(dist(i,:)) > 1
                    
                    all_dist = sort(dist(i,:));
                    second_min_index = find(dist(i,:)==all_dist(2));
                    if ~isinf(all_dist(2))  && all_dist(2) < 200 &&  isempty(find(min_dis_vector==second_min_index, 1))

%                             body_prop(second_min_index).Centroid(1) > people_array{prev_index}.BoundingBox(1) && ...
%                             body_prop(second_min_index).Centroid(1) < people_array{prev_index}.BoundingBox(1)+ people_array{prev_index}.BoundingBox(3) && ...
%                             body_prop(second_min_index).Centroid(2) > people_array{prev_index}.BoundingBox(2) && ...
%                             body_prop(second_min_index).Centroid(2) < people_array{prev_index}.BoundingBox(2)+ people_array{prev_index}.BoundingBox(4) && ...
                        
                        total_area = body_prop(second_min_index).Area + body_prop(min_arg).Area;
                        if total_area < 2 * people_array{prev_index}.Area 
                            bb = body_prop(second_min_index).BoundingBox;
                            total_flow = sum(sum( flow.Magnitude(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1)));
                            if total_flow > 1000
                                % pass
                                
                                b_2 = body_prop(second_min_index);
                                b_1 = body_prop(min_arg);
                                
                                people_array{prev_index}.Centroid = (body_prop(min_arg).Centroid*body_prop(min_arg).Area + ...
                                    body_prop(second_min_index).Centroid * body_prop(second_min_index).Area) / ...
                                    (body_prop(second_min_index).Area + body_prop(min_arg).Area);
                                
                                del_index_of_body = [del_index_of_body; second_min_index];
                                
                                % bbox
                                x_t = min( b_2.BoundingBox(1), b_1.BoundingBox(1) );
                                y_t = min( b_2.BoundingBox(2), b_1.BoundingBox(2) );
                                
                                x_end_t = max( b_2.BoundingBox(1)+b_2.BoundingBox(3)-1, b_1.BoundingBox(1)+b_1.BoundingBox(3)-1 );
                                y_end_t = max( b_2.BoundingBox(2)+b_2.BoundingBox(4)-1, b_1.BoundingBox(2)+b_1.BoundingBox(4)-1 );
                                
                                people_array{prev_index}.BoundingBox = [x_t, y_t, x_end_t-x_t+1, y_end_t-y_t+1];
                                
                                people_array{prev_index}.Area = body_prop(min_arg).Area+b_2.Area;
                                
                                
                            end
                        end
                    end
                end
                
                people_array{prev_index}.Orientation = body_prop(min_arg).Orientation;
                people_array{prev_index}.temp_count = 0;
                new_features = get_features(im_r, body_prop(min_arg).BoundingBox, im_binary);
                people_array{prev_index}.features = 0.5 * new_features + 0.5 * people_array{prev_index}.features;
                
            else
                % more than one bounding box matched
                
                x_c = body_prop(vect(i)).Centroid(1);
                y_c = body_prop(vect(i)).Centroid(2);
                L = body_prop(vect(i)).MajorAxisLength;
                theta = -deg2rad(body_prop(vect(i)).Orientation);
                if theta < 0
                    theta = theta + pi;
                end
                
                prev_ind = find(min_dis_vector(:,2) == vect(i));
                
                prev_ind = prev_ind(min_dis_vector(prev_ind, 1) <= 500*scale);
                
                if length(prev_ind) == 1
                    
                    del_index_of_body = [del_index_of_body; vect(i)];
                    people_array{prev_ind}.Centroid = body_prop(vect(i)).Centroid;
                    people_array{prev_ind}.Orientation = body_prop(vect(i)).Orientation;
                    people_array{prev_ind}.BoundingBox = body_prop(vect(i)).BoundingBox;
                    people_array{prev_ind}.color_val = get_color_val(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    people_array{prev_ind}.Area = body_prop(vect(i)).Area;
                    people_array{prev_ind}.temp_count = 0;
                    new_features = get_features(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    people_array{prev_ind}.features = 0.5 * new_features + 0.5 *  people_array{prev_ind}.features;
                    continue;
                end
                
                prev_people = [people_array_struct(prev_ind)];
                list_centroid = [prev_people.Centroid];
                [~,I] = sort(list_centroid(2,:), 'descend');
                
                thres_area = 0.9;
                if length(prev_ind) == 2 && body_prop(vect(i)).Area < thres_area * sum([prev_people.Area])
                    % assuming two objects
                    [~, min_tmp_index] = min(min_dis_vector(prev_ind,1));
                    
                    % set matching to nearest body
                    del_index_of_body = [del_index_of_body; vect(i)];
                    people_array{min_tmp_index}.Centroid = body_prop(vect(i)).Centroid;
                    people_array{min_tmp_index}.Orientation = body_prop(vect(i)).Orientation;
                    people_array{min_tmp_index}.BoundingBox = body_prop(vect(i)).BoundingBox;
                    people_array{min_tmp_index}.temp_count = 0;
                    %people_array{min_tmp_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                    %people_array{min_tmp_index}.Area = body_prop(min_arg).Area;
                    
                    [~, other_index] = max(min_dis_vector(prev_ind,1));
                    [other_sorted_distance, index_vector] = sort(dist(other_index,:));
                    if length(index_vector) > 1
                        other_matched_index = index_vector(2);
                        if isempty(find( min_dis_vector(:,2) == other_matched_index, 1 )) && other_sorted_distance(2) < min_allowed_dis
                            people_array{other_index}.Centroid = body_prop(other_matched_index).Centroid;
                            people_array{other_index}.Orientation = body_prop(other_matched_index).Orientation;
                            people_array{other_index}.BoundingBox = body_prop(other_matched_index).BoundingBox;
                            del_index_of_body = [del_index_of_body; other_matched_index];
                            people_array{other_index}.temp_count = 0;
                        else
                            % temporary vanishing
                            people_array{other_index}.state = "temporary_vanishing";
                            people_array{other_index}.temp_count = people_array{other_index}.temp_count+1;
                        end
                    else
                        % temporary vanishing
                        people_array{other_index}.state = "temporary_vanishing";
                        people_array{other_index}.temp_count = people_array{other_index}.temp_count+1;
                    end
                    
                else
                    
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
        end
        
    end
    
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
    bb = body_prop(i).BoundingBox;
    total_flow = flow.Magnitude(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1);
    if body_prop(i).Centroid(2) < half_y && body_prop(i).Area > limit_init_area && sum(sum(total_flow)) > 1500 && ...
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
        features = get_features(im_r, body_prop(i).BoundingBox, im_binary);
        Person = struct('Area', body_prop(i).Area, 'Centroid', body_prop(i).Centroid, ...
            'Orientation', body_prop(i).Orientation, 'BoundingBox', body_prop(i).BoundingBox, ...
            'state', "unspec", 'color_val', color_val, 'label', R_dropping.label, ...
            'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0, 'features', features);
        R_dropping.label = R_dropping.label + 1;
        people_array{end+1} = Person;
        
    end
end



%% check exit from c9
check_10_threshold = 400;
del_exit_from_c9 = [];
for i = 1:numel(R_dropping.exit_from_9)
    if i>1
        R_dropping.exit_from_9{i}.temp_count = R_dropping.exit_from_9{i}.temp_count + 1;
        if R_dropping.exit_from_9{i}.temp_count  > check_10_threshold
            people_seq{end+1} = R_dropping.exit_from_9{i};
            del_exit_from_c9(end+1) = i;
            disp('exit......');
        end
        continue;
    end
    
    cur_people = R_dropping.exit_from_9{1};
    if cur_people.temp_count <= check_10_threshold
        
        if cur_people.temp_count == 0
            R_dropping.v10.currentTime = currentTime;
            cur_people.temp_count = cur_people.temp_count + 1;
        end
        
        if hasFrame(R_dropping.v10)
            img = readFrame(R_dropping.v10);
            im_c = imresize(img,scale);
            r = R_dropping.r_c10;
            im_p10 = rgb2gray(R_dropping.im_back_c10(r(3):r(4),r(1):r(2),:));
            im_r10 = rgb2gray(im_c(r(3):r(4),r(1):r(2),:));
            
            %% Region 1 background subtraction
            
            threshold = 60;
            im_fore = abs(im_r10-im_p10) + abs(im_p10 - im_r10);
            %im_fore(im_fore < 0.2) = 0;
            
            im_fore = uint8(im_fore);
            im_fore(im_fore < threshold) = 0;
            im_filtered = imgaussfilt(im_fore, 6);
            im_filtered(im_filtered < 50) = 0;
            se = strel('disk',10);
            im_closed = imclose(im_filtered,se);
            
            im_binary_10 = logical(im_closed); %extract people region
            
            cpro_r1 = regionprops(im_binary_10, 'Centroid', 'Area', 'Orientation', 'BoundingBox'); % extract parameters
            im_draw_10 = im_r10;
            % body_prop_10 = [];
            flag_found = 0;
            for k = 1:size(cpro_r1, 1)
                if cpro_r1(k).Area > 1000
                    % body_prop_10 = [body_prop_10; cpro_r1(k)];
                    % found
                    flag_found = 1;
                    if debug_people
                        im_draw_10 = insertShape(im_draw_10, 'Rectangle', int32(cpro_r1(i).BoundingBox), 'LineWidth', 10);
                    end
                    
                    break;
                end
            end
            
            if flag_found == 1
                cur_people.temp_count = -1;
            elseif cur_people.temp_count == -1
                people_seq{end+1} = R_dropping.exit_from_9{1};
                del_exit_from_c9(end+1) = 1;
                disp('exit......');
            else
                cur_people.temp_count = cur_people.temp_count + 1;
            end
            
            if debug_people
                
                figure(5); imshow(im_draw_10);
            end
            
        end
    else
        people_seq{end+1} = R_dropping.exit_from_9{1};
        del_exit_from_c9(end+1) = 1;
        disp('exit......');
    end
    
    R_dropping.exit_from_9{1} = cur_people;
    
end
if ~isempty(del_exit_from_c9)
    R_dropping.exit_from_9(del_exit_from_c9) = [];
end

im_draw = im_r;


%figure(2); imshow(im_draw);

% sort people
if ~isempty(people_array)
    people_array_struct = [people_array{:}];
    list_centroid = [people_array_struct.Centroid];
    [~,I] = sort(list_centroid(2,:), 'descend');
    people_array = {people_array{I}};
end
%% some test image
if ~isempty(R_dropping.prev_body) && debug_people
    %figure(2); imshow(im_draw);
    
    %im_diff = uint8(abs(double(im_r(:,:,2)) - double(R_dropping.prev_body)));
    %figure(4);imshow(im_binary);

    
    for i = 1:size(im_draw,1)
        for j = 1:size(im_draw,2)            
            if im_binary(i,j)==1
               im_draw(i,j,1) = 200;
            end
        end
    end
    
    for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1) ...
        people_array{i}.BoundingBox(2) ...
        people_array{i}.BoundingBox(3) ...
        people_array{i}.BoundingBox(4) ];
    im_draw = insertShape(im_draw, 'Rectangle', people_array{i}.BoundingBox, 'LineWidth', 5, 'Color', 'blue');
    im_draw = insertShape(im_draw, 'FilledCircle', [people_array{i}.Centroid' 10], 'Color', 'blue' );
    text_ = sprintf('person:%d', people_array{i}.label);
    im_draw = insertText(im_draw, bounding_box(1:2), text_, 'FontSize', 20);
    end
    
    figure(2);
    imshow(im_draw);
    hold off;
    
    figure(3); imshow(im_binary);
    
    drawnow;
    
end

R_dropping.prev_body = im_r;

end

