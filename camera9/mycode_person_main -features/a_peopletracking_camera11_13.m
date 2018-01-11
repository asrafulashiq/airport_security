function [R_main, R_com_info, R_11, R_13] = a_peopletracking_camera11_13(im_r,R_main, R_people_var, R_com_info, R_c9, camera_no, R_11, R_13)
%% region 1 extraction
global scale;
global debug_people_11;
global debug_people_13;
global associate;

thres_low   =  R_people_var.thres_low;
thres_up    =  R_people_var.thres_up;
min_allowed_dis =  R_people_var.min_allowed_dis;
limit_area  =  R_people_var.limit_area;
limit_small_area = R_people_var.limit_small_area;
limit_init_area  =   R_people_var.limit_init_area;
limit_max_width  =   R_people_var.limit_max_width;
limit_max_height =  R_people_var.limit_max_height;
half_y         =   R_people_var.half_y;
limit_exit_y1  =  R_people_var.limit_exit_y1;
limit_exit_x1  =  R_people_var.limit_exit_x1;
limit_exit_y2  =  R_people_var.limit_exit_y2 ;
limit_exit_x2  =  R_people_var.limit_exit_x2;
threshold_img  =  R_people_var.threshold_img;
init_max_x = 127 * 2 * scale;

thres_critical_del  =    R_people_var.thres_critical_del ;
thres_temp_count_low  =    R_people_var.thres_temp_count_low;
thres_temp_count_high  =    R_people_var.thres_temp_count_high;

critical_exit_x   =   R_people_var.critical_exit_x ;
critical_exit_y    =  R_people_var.critical_exit_y ;

im_g = rgb2gray(im_r);
flow = estimateFlow(R_main.R_people.optic_flow, im_g);
R_main.R_people.flow = flow;

exit_vanishing_area = 30000 * scale^2;
%% Region 1 background subtraction based on chromatic value
im_r = imgaussfilt(im_r, 5);
im_back = R_main.R_people.im_r1_p;
im_back = imgaussfilt(im_back, 5);

im_r_hsv = rgb2hsv(im_r);
im_p_hsv = rgb2hsv(im_back);

im_fore = abs(im_r_hsv(:,:,2)-im_p_hsv(:,:,2)) + abs(im_p_hsv(:,:,2) - im_r_hsv(:,:,2));
im_fore = uint8(im_fore * 255 * 0.5);

im_filtered = imgaussfilt(im_fore, 6);
im_filtered(im_filtered < threshold_img) = 0;
% close operation for the image
se = strel('disk',15);
im_closed = imclose(im_filtered,se);
%im_eroded = imerode(im_closed, se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');
%im_binary = logical(im_eroded);

%% blob analysis
cpro_r1_main = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'MajorAxisLength'); % extract parameters
body_prop = cpro_r1_main([cpro_r1_main.Area] > limit_area);
body_prop_all = cpro_r1_main([cpro_r1_main.Area] > limit_small_area);
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
if ~isempty(R_main.people_array) && ~isempty(list_bbox)
    for i = 1:size(R_main.people_array,2)
        
        % detect exit from camera 13 to 11
        if camera_no == 13
            
            if R_main.people_array{i}.Centroid(2) < R_people_var.init_limit_exit_y1 - 10 %&& R_people_var.people_array{i}.Centroid(1) < R_main.init_limit_exit_x1
                
                R_com_info.check_11 = 1;
                R_com_info.check_13 = 0;
                R_com_info.id = R_main.people_array{i}.id;
                
                if numel(R_main.people_seq) > 0 && ~isempty(find([R_main.people_seq.id] == R_com_info.id, 1))
                    index = find([R_main.people_seq.id] == R_com_info.id, 1);
                    R_main.people_seq(index) = R_main.people_array{i};
                else
                    R_main.people_seq = [R_main.people_seq;R_main.people_array{i}];
                end
                
                R_main.people_array{i}.temp_count = 0;
                %R_main.R_people.exit_from_9{end+1} = R_main.people_array{i};
                exit_index_people_array(end+1) = i;
                disp('exit......');
                continue;
                
                
            end
            
        end
        
        % detect exit from camera 11
        if ( R_main.people_array{i}.Centroid(2) > limit_exit_y1 && R_main.people_array{i}.Centroid(1) > limit_exit_x1 ) || ...
                ( R_main.people_array{i}.Centroid(2) > limit_exit_y2 && R_main.people_array{i}.Centroid(1) > limit_exit_x2 && ...
                (~isempty(R_main.people_array) && R_main.people_array{i}.critical_del >= thres_critical_del)) % R_main.people_array{i}.Area < exit_vanishing_area
            
            % && R_main.people_array{i}.Centroid(2) > half_y)
            
            % detect exit from camera 11 to camera 13
            if camera_no == 11
                R_com_info.check_13 = 1;
                R_com_info.check_11 = 0;
                R_com_info.id = R_main.people_array{i}.id;
                R_com_info.label = R_main.people_array{i}.label;
                half_y = 473;
            end
            
            if numel(R_main.people_seq) > 0 && ~isempty(find([R_main.people_seq.id] == R_com_info.id, 1))
                index = find([R_main.people_seq.id] == R_com_info.id, 1);
                R_main.people_seq(index) = R_main.people_array{i};
            else
                R_main.people_seq = [R_main.people_seq; R_main.people_array{i}];
            end
            
            R_main.people_array{i}.temp_count = 0;
            exit_index_people_array(end+1) = i;
            disp('exit......');
            continue;
        end
        
        if R_main.people_array{i}.state=="temporary_vanishing"
            if (R_main.people_array{i}.Centroid(1) > limit_exit_x1 && R_main.people_array{i}.temp_count > thres_temp_count_low) || ...
                    (R_main.people_array{i}.Centroid(1) > limit_exit_x2 && R_main.people_array{i}.temp_count > thres_temp_count_high) ...
                    || (R_main.people_array{i}.temp_count > 400)
                R_main.people_seq = [R_main.people_seq; R_main.people_array{i}];
                exit_index_people_array(end+1) = i;
                disp('exit......');
                continue;
            end
        end
        
        if R_main.people_array{i}.Centroid(1) > critical_exit_x && R_main.people_array{i}.Centroid(2) > critical_exit_y
            
            if (R_main.people_array{i}.critical_del) == -1000
                R_main.people_array{i}.prev_centroid = R_main.people_array{i}.Centroid(1);
                R_main.people_array{i}.critical_del = 0;
            else
                if R_main.people_array{i}.Centroid(1) > R_main.people_array{i}.prev_centroid
                    R_main.people_array{i}.critical_del = R_main.people_array{i}.critical_del + 1;
                else
                    R_main.people_array{i}.critical_del = R_main.people_array{i}.critical_del - 1;
                end
            end
        else
            if (R_main.people_array{i}.critical_del) ~= -1000
                R_main.people_array{i}.critical_del = -1000;
            end
        end
    end
    
    R_main.people_array(exit_index_people_array) = [];
    people_array_struct = [R_main.people_array{:}];
    % determine minimum distance
    min_dis_vector = [];
    
    if ~isempty(R_main.people_array)
        
        dist = pdist2(double([people_array_struct.Centroid]'), double(list_bbox));
        for i = 1:size(R_main.people_array,2)
            dist_ = dist(i,:);
            [min_dis, min_arg] = min(dist_);
            
            min_dis_vector = [min_dis_vector; min_dis min_arg];
        end
        
        %%%%
        
        
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
                    %&& R_main.people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * R_main.people_array{i}.Area
                    % divide area and match
                    [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, R_main.people_array{prev_index}, flow);
                    
                    if ~isempty(bbox_matched)
                        del_index_of_body = [del_index_of_body; min_arg];
                        R_main.people_array{prev_index}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                        R_main.people_array{prev_index}.BoundingBox = bbox_matched;
                        R_main.people_array{prev_index}.temp_count = 0;
                    end
                    continue;
                end
                
                if dist(prev_index, min_arg) > min_allowed_dis || body_prop(min_arg).Area <  0.3 * R_main.people_array{prev_index}.Area
                    R_main.people_array{prev_index}.state = "temporary_vanishing";
                    R_main.people_array{prev_index}.temp_count = R_main.people_array{prev_index}.temp_count+1;
                    continue;
                end
                
                R_main.people_array{prev_index}.Centroid = body_prop(min_arg).Centroid;
                del_index_of_body = [del_index_of_body; min_arg];
                
                R_main.people_array{prev_index}.BoundingBox = body_prop(min_arg).BoundingBox;
                R_main.people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                R_main.people_array{prev_index}.Area = body_prop(min_arg).Area;
                
                % check second minimum value
                if length(dist(i,:)) > 1
                    
                    all_dist = sort(dist(i,:));
                    second_min_index = find(dist(i,:)==all_dist(2));
                    if ~isinf(all_dist(2))  && all_dist(2) < 200 &&  isempty(find(min_dis_vector==second_min_index, 1))
                        
                        total_area = body_prop(second_min_index).Area + body_prop(min_arg).Area;
                        if total_area < 2 * R_main.people_array{prev_index}.Area
                            bb = body_prop(second_min_index).BoundingBox;
                            total_flow = sum(sum( flow.Magnitude(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1)));
                            if total_flow > 1000
                                % pass
                                
                                b_2 = body_prop(second_min_index);
                                b_1 = body_prop(min_arg);
                                
                                R_main.people_array{prev_index}.Centroid = (body_prop(min_arg).Centroid*body_prop(min_arg).Area + ...
                                    body_prop(second_min_index).Centroid * body_prop(second_min_index).Area) / ...
                                    (body_prop(second_min_index).Area + body_prop(min_arg).Area);
                                
                                del_index_of_body = [del_index_of_body; second_min_index];
                                
                                % bbox
                                x_t = min( b_2.BoundingBox(1), b_1.BoundingBox(1) );
                                y_t = min( b_2.BoundingBox(2), b_1.BoundingBox(2) );
                                
                                x_end_t = max( b_2.BoundingBox(1) + b_2.BoundingBox(3)-1, b_1.BoundingBox(1)+b_1.BoundingBox(3)-1 );
                                y_end_t = max( b_2.BoundingBox(2) + b_2.BoundingBox(4)-1, b_1.BoundingBox(2)+b_1.BoundingBox(4)-1 );
                                
                                R_main.people_array{prev_index}.BoundingBox = [x_t, y_t, x_end_t-x_t+1, y_end_t-y_t+1];
                                
                                R_main.people_array{prev_index}.Area = body_prop(min_arg).Area + b_2.Area;
                                
                            end
                        end
                    end
                end
                
                R_main.people_array{prev_index}.Orientation = body_prop(min_arg).Orientation;
                R_main.people_array{prev_index}.temp_count = 0;
                new_features = get_features(im_r, body_prop(min_arg).BoundingBox, im_binary);
                R_main.people_array{prev_index}.features = 0.5 * new_features + 0.5 * R_main.people_array{prev_index}.features;
                
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
                    R_main.people_array{prev_ind}.Centroid = body_prop(vect(i)).Centroid;
                    R_main.people_array{prev_ind}.Orientation = body_prop(vect(i)).Orientation;
                    R_main.people_array{prev_ind}.BoundingBox = body_prop(vect(i)).BoundingBox;
                    R_main.people_array{prev_ind}.color_val = get_color_val(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    R_main.people_array{prev_ind}.Area = body_prop(vect(i)).Area;
                    R_main.people_array{prev_ind}.temp_count = 0;
                    new_features = get_features(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    R_main.people_array{prev_ind}.features = 0.5 * new_features + 0.5 *  R_main.people_array{prev_ind}.features;
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
                    R_main.people_array{min_tmp_index}.Centroid = body_prop(vect(i)).Centroid;
                    R_main.people_array{min_tmp_index}.Orientation = body_prop(vect(i)).Orientation;
                    R_main.people_array{min_tmp_index}.BoundingBox = body_prop(vect(i)).BoundingBox;
                    R_main.people_array{min_tmp_index}.temp_count = 0;
                    %R_main.people_array{min_tmp_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                    %R_main.people_array{min_tmp_index}.Area = body_prop(min_arg).Area;
                    
                    [~, other_index] = max(min_dis_vector(prev_ind,1));
                    [other_sorted_distance, index_vector] = sort(dist(other_index,:));
                    if length(index_vector) > 1
                        other_matched_index = index_vector(2);
                        if isempty(find( min_dis_vector(:,2) == other_matched_index, 1 )) && other_sorted_distance(2) < min_allowed_dis
                            R_main.people_array{other_index}.Centroid = body_prop(other_matched_index).Centroid;
                            R_main.people_array{other_index}.Orientation = body_prop(other_matched_index).Orientation;
                            R_main.people_array{other_index}.BoundingBox = body_prop(other_matched_index).BoundingBox;
                            del_index_of_body = [del_index_of_body; other_matched_index];
                            R_main.people_array{other_index}.temp_count = 0;
                        else
                            % temporary vanishing
                            R_main.people_array{other_index}.state = "temporary_vanishing";
                            R_main.people_array{other_index}.temp_count = R_main.people_array{other_index}.temp_count+1;
                        end
                    else
                        % temporary vanishing
                        R_main.people_array{other_index}.state = "temporary_vanishing";
                        R_main.people_array{other_index}.temp_count = R_main.people_array{other_index}.temp_count+1;
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
                        R_main.people_array{prev_ind(index)}.Centroid = cent;
                        
                        % update bounding box
                        width = R_main.people_array{prev_ind(index)}.BoundingBox(3);
                        height = R_main.people_array{prev_ind(index)}.BoundingBox(4);
                        x = max(cent(1) - width / 2, 1);
                        y = max(cent(2) - height / 2, 1);
                        x_ = min(cent(1) + width / 2, size(im_r, 2));
                        y_ = min(cent(2) + height / 2, size(im_r, 1));
                        
                        wid = x_ - x + 1;
                        hei = y_ - y + 1;
                        
                        bbox = [x y wid hei];
                        R_main.people_array{prev_ind(index)}.BoundingBox = bbox;
                        
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

for i = 1:size(R_main.people_array, 2)
    if R_main.people_array{i}.BoundingBox(3)>limit_max_width || R_main.people_array{i}.BoundingBox(4)>limit_max_height
        centre_rec =  [  R_main.people_array{i}.BoundingBox(1)+R_main.people_array{i}.BoundingBox(3)/2 ...
            R_main.people_array{i}.BoundingBox(2)+R_main.people_array{i}.BoundingBox(4)/2  ];
        
        if R_main.people_array{i}.BoundingBox(3) > limit_max_width
            R_main.people_array{i}.BoundingBox(3) = limit_max_width;
            R_main.people_array{i}.BoundingBox(1) = centre_rec(1) - limit_max_width / 2;
        end
        
        if R_main.people_array{i}.BoundingBox(4) > limit_max_height
            R_main.people_array{i}.BoundingBox(4) = limit_max_height;
            R_main.people_array{i}.BoundingBox(2) = centre_rec(2) - limit_max_height / 2;
        end
        R_main.people_array{i}.BoundingBox = int32(R_main.people_array{i}.BoundingBox);
        R_main.people_array{i}.Area = sum(sum(imcrop(im_binary, R_main.people_array{i}.BoundingBox)));
        %color_val = get_color_val(im_r, R_main.people_array{i}.BoundingBox, im_binary );
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
    
    % inital detection from 11 to 13
    if camera_no == 13 && R_com_info.check_13 ~= 0
        
        if body_prop(i).Centroid(2) > R_people_var.init_limit_exit_y1 && body_prop(i).Centroid(2) < half_y
            limit_flag = false;
            centre_rec =  [ body_prop(i).BoundingBox(1)+body_prop(i).BoundingBox(3)/2  body_prop(i).BoundingBox(2)+body_prop(i).BoundingBox(4)/2  ];
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
                'state', "unspec", 'color_val', color_val, 'label', R_com_info.label, 'id', R_com_info.id, ...
                'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0, 'features', features);
            
            if Person.label >= R_main.R_people.label
                R_main.R_people.label = R_main.R_people.label + 1;
            end
            
            R_main.people_array{end+1} = Person;
            
            continue;
        end
    end
    
    % initial detection from 13 to 11
    if camera_no == 11 && R_com_info.check_11 ~= 0
        
        if body_prop(i).Centroid(2) < R_people_var.limit_exit_y2 + 10 && body_prop(i).Centroid(2) > R_people_var.half_y
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
                'state', "unspec", 'color_val', color_val, 'label',  R_com_info.label, 'id', R_com_info.id, ...
                'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0, 'features', features);
            
            if Person.label >= R_main.R_people.label
                R_main.R_people.label = R_main.R_people.label + 1;
            end
            
            R_main.people_array{end+1} = Person;
            
            continue;
        end        
    end
    
    if body_prop(i).Centroid(2) < half_y && body_prop(i).Area > limit_init_area && sum(sum(total_flow)) > 1500 && ...
            body_prop(i).Centroid(2) < limit_exit_y1 && body_prop(i).Centroid(1) < init_max_x
        
        if camera_no == 13      
            if  body_prop(i).Centroid(2) < half_y
                continue;
            end
        end
        
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
            'state', "unspec", 'color_val', color_val, 'label', R_main.R_people.label, 'id', R_main.R_people.label, ...
            'critical_del', -1000, 'prev_centroid',[], 'temp_count', 0, 'features', features);
        
        if associate
            label_num = Person.label;
            if numel(R_c9.people_seq) >= label_num
                intended_label = R_c9.people_seq(label_num).label;
                Person.id = intended_label;
            end
        end
      
        R_main.R_people.label = R_main.R_people.label + 1;
        R_main.people_array{end+1} = Person;
        
    end
end

%% check exit from c9
check_10_threshold = 400;

im_draw = im_r;
for i = 1:size(R_main.people_array, 2)
    
    im_draw = insertShape(im_draw, 'Rectangle', R_main.people_array{i}.BoundingBox, 'LineWidth', 10);
    im_draw = insertShape(im_draw, 'FilledCircle', [R_main.people_array{i}.Centroid' 20] );
    
end

%figure(2); imshow(im_draw);

% sort people
if ~isempty(R_main.people_array)
    people_array_struct = [R_main.people_array{:}];
    list_centroid = [people_array_struct.Centroid];
    [~,I] = sort(list_centroid(2,:), 'descend');
    R_main.people_array = {R_main.people_array{I}};
end
%% some test image
if ~isempty(R_main.R_people.prev_body) && ( debug_people_11 || debug_people_13)
    
    if debug_people_11
        figure(4);
    else
        figure(6);
    end
    
    imshow(im_binary);
    
    if debug_people_11
        figure(5);
    else
        figure(7);
    end
    imshow(im_draw);
    
    drawnow;
    
end

R_main.R_people.prev_body = im_r;

end

