function [R_people, R2_people] = people_detector_tracking(im_r, im_flow, R_people, R2_people)

%global scale;
global debug_9;
%im_g = rgb2gray(im_r);

%% flow segmentation
im_flow_g = rgb2gray(im_flow);
im_flow_hsv = rgb2hsv(im_flow);

im_filtered = imgaussfilt(im_flow_g, 6);
%im_tmp = im_filtered;
im_filtered(im_filtered < R_people.threshold_img) = 0;

% close operation for the image
se = strel('disk',15);
im_closed = imclose(im_filtered,se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');

figure(4); imshow(im_binary);

%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','BoundingBox','Orientation', ...
    'MajorAxisLength', 'MinorAxisLength'); % extract parameters

body_prop = {};
list_bbox = [];

X1 = [100 66]; X2 = [146 279];
A = ([X1;X2]) \ [-1;-1];
aa = A(1)/norm(A); bb = A(2)/norm(A); cc = 1/norm(A);

for i = 1:numel(cpro_r1)
    
    x = cpro_r1(i).Centroid;
    d = aa*x(1)+bb*x(2)+cc;
    inc = 0;
    if  ( d<60 && x(2) > 200 ) || x(1) > R_people.limit_exit_x
        if cpro_r1(i).Area > R_people.limit_area %&& cpro_r1(i).Area<R_people.limit_init_max_area
            inc =1;
        end
    elseif cpro_r1(i).Area > R_people.limit_init_area %&& cpro_r1(i).Area<R_people.limit_init_max_area
        inc = 1;
    end
    
    if inc==1
        list_bbox = [list_bbox; cpro_r1(i).Centroid];
        cpro_r1(i).Centroid = cpro_r1(i).Centroid';
        body_prop{end+1} = cpro_r1(i);
        
    end
end

body_prop = [body_prop{:}];

%% detect

%%%%% TODO: exclude currently tracked person
del_index_of_body = [];

%% matching

if ~isempty(R_people.people_array) && ~isempty(list_bbox)
    
    del_exit = [];
    for i = 1:numel(R_people.people_array)
        
        [a, m] = calcAngleMag(im_flow_hsv, im_binary, R_people.people_array{i}.BoundingBox);
        R_people.people_array{i}.flow_angle = a;
        R_people.people_array{i}.flow_mag = m;
        
        % detect exit
        person = R_people.people_array{i};
        
        x = person.Centroid;
        d = aa*x(1)+bb*x(2)+cc;
        
        if person.Centroid(1) > R_people.limit_exit_x && ...
                person.Centroid(2) >  R_people.limit_exit_y
            del_exit(end+1) = i;
        end
        
        if d < 45 && person.Centroid(2) > R_people.limit_exit_y2 &&   ...
                (person.flow_angle) > 30 && (person.flow_angle) < 180 && ...
                person.Area < R_people.limit_exit_max_area
            del_exit(end+1) = i;
        end
        R_people.people_array{i}.counter = R_people.people_array{i}.counter + 1;
    end
    
    for k = del_exit
        
        if nargin > 3 % tell camera 2 to check
            flg = 0;
            for ll = 1:numel(R2_people.stack_of_people)
               if R2_people.stack_of_people{ll}.label==R_people.people_array{k}.label
                    flg = 1;
                    break;
               end
            end
            if flg==0
                R2_people.stack_of_people{end+1} = R_people.people_array{k};
                R2_people.stack_of_people{end}.Centroid(2) = ...
                    R2_people.stack_of_people{end}.Centroid(2) + 20;
            end
        else
            R_people.people_seq{end+1} = R_people.people_array{k};
        end
    end
    
    if nargin <=3
        R_people.people_array(del_exit) = [];
    end
    
    if numel(R_people.people_array) ~= 0
        
        tmp_del = 1:numel(R_people.people_array);
        
        for i = 1:numel(R_people.people_array)
            
            % if flow magnitude is less than particular value, don't update
            if R_people.people_array{i}.flow_mag < R_people.limit_flow_mag
                tmp_del(i) = 0;
            end
        end
        tmp_del(tmp_del==0) = [];
        
        people_array_struct = [R_people.people_array{tmp_del}];
        % determine minimum distance
        min_dis_vector = [];
        if ~isempty(people_array_struct)
            mag_scale = 50;
            X_arr = [ [people_array_struct.Centroid]' [people_array_struct.flow_angle]' [people_array_struct.flow_mag]'*mag_scale ];
            dist = pdist2(double(X_arr),double([list_bbox zeros(size(list_bbox,1), 2)] ), @(X,Z) distfun(X,Z,R_people.limit_max_displacement));
            for i = 1:numel(people_array_struct) %(R_people.people_array)
                dist_ = dist(i,:);
                [min_dis, min_arg] = min(dist_);
                min_dis_vector = [min_dis_vector; min_dis min_arg];
            end
            
            % resolve conflict
            vect = unique(min_dis_vector(:,2),'stable');
            count_el = zeros(1,length(vect));
            for tmp_i = 1:size(vect)
                
                count_el(tmp_i) = sum( min_dis_vector(:,2) == vect(tmp_i) & ...
                    ~isinf(min_dis_vector(:,1)));
            end
            
            for i = 1:length(vect)
                if count_el(i) == 1
                    % only one bounding box match
                    prev_index = find(min_dis_vector(:,2) == vect(i) & ~isinf(min_dis_vector(:,1)));
                    prev_index_p = tmp_del(prev_index);
                    if isinf(min_dis_vector(prev_index, 1)) || ...
                            ~ ( body_prop(min_arg).Area < 3*R_people.people_array{prev_index_p}.Area && ...
                            (body_prop(min_arg).Area > 0.5 * R_people.people_array{prev_index_p}.Area && body_prop(min_arg).Centroid(1) < R_people.limit_half_x && ...
                            body_prop(min_arg).Area > R_people.limit_init_area  ) || ...
                            (body_prop(min_arg).Area > 0.3 * R_people.people_array{prev_index_p}.Area && body_prop(min_arg).Centroid(1) >= R_people.limit_half_x))
                        
                        continue;
                    end
                    
                    if min_dis_vector(prev_index, 1) > R_people.min_allowed_dis
                        continue;
                    end
                    
                    min_arg = vect(i);
                    
                    
                    if body_prop(min_arg).BoundingBox(3)>R_people.limit_max_width || body_prop(min_arg).BoundingBox(4)>R_people.limit_max_height
                        %&& R_people.people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * R_people.people_array{i}.Area
                        % divide area and match
                        [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, R_people.people_array{prev_index_p}, R_people.im);
                        
                        if ~isempty(bbox_matched) && ...
                                check_max_overlap_people(bbox_matched, R_people.people_array, prev_index_p) < R_people.max_overlap
                            
                            del_index_of_body = [del_index_of_body; min_arg];
                            R_people.people_array{prev_index_p}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                            R_people.people_array{prev_index_p}.BoundingBox = bbox_matched;
                            R_people.people_array{prev_index_p}.temp_count = 0;
                            
                            cnt = R_people.people_array{prev_index_p}.color_count;
                            R_people.people_array{prev_index_p}.color_mat(mod(cnt,40)+1,:) = get_color_val(im_r, ...
                                R_people.people_array{prev_index_p}.BoundingBox, im_binary);
                            R_people.people_array{prev_index_p}.color_count = R_people.people_array{prev_index_p}.color_count + 1;
                        end
                        continue;
                    end
                    
                    
                    if check_max_overlap_people(body_prop(min_arg).BoundingBox, R_people.people_array, prev_index_p) > R_people.max_overlap
                        continue;
                    end
                    
                    R_people.people_array{prev_index_p}.Centroid = body_prop(min_arg).Centroid;
                    del_index_of_body = [del_index_of_body; min_arg];
                    
                    R_people.people_array{prev_index_p}.BoundingBox = body_prop(min_arg).BoundingBox;
                    %R_people.people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                    R_people.people_array{prev_index_p}.Area = 0.7 * body_prop(min_arg).Area + 0.3 * R_people.people_array{prev_index_p}.Area;
                    
                    cnt = R_people.people_array{prev_index_p}.color_count;
                    R_people.people_array{prev_index_p}.color_mat(mod(cnt,100)+1,:) = get_color_val(im_r, ...
                        R_people.people_array{prev_index_p}.BoundingBox, im_binary);
                    R_people.people_array{prev_index_p}.color_count = R_people.people_array{prev_index_p}.color_count + 1;
                    
                    
                    % check second minimum value
                    if length(dist(i,:)) > 1
                        
                        all_dist = sort(dist(i,:));
                        second_min_index = find(dist(i,:)==all_dist(2));
                        if ~isinf(all_dist(2))  && all_dist(2) < 200 &&  isempty(find(min_dis_vector==second_min_index, 1))
                            
                            total_area = body_prop(second_min_index).Area + body_prop(min_arg).Area;
                            if total_area < 2 * R_people.people_array{prev_index_p}.Area
                                bb = body_prop(second_min_index).BoundingBox;
                                % pass
                                
                                b_2 = body_prop(second_min_index);
                                b_1 = body_prop(min_arg);
                                
                                R_people.people_array{prev_index_p}.Centroid = (body_prop(min_arg).Centroid*body_prop(min_arg).Area + ...
                                    body_prop(second_min_index).Centroid * body_prop(second_min_index).Area) / ...
                                    (body_prop(second_min_index).Area + body_prop(min_arg).Area);
                                
                                del_index_of_body = [del_index_of_body; second_min_index];
                                
                                % bbox
                                x_t = min( b_2.BoundingBox(1), b_1.BoundingBox(1) );
                                y_t = min( b_2.BoundingBox(2), b_1.BoundingBox(2) );
                                
                                x_end_t = max( b_2.BoundingBox(1)+b_2.BoundingBox(3)-1, b_1.BoundingBox(1)+b_1.BoundingBox(3)-1 );
                                y_end_t = max( b_2.BoundingBox(2)+b_2.BoundingBox(4)-1, b_1.BoundingBox(2)+b_1.BoundingBox(4)-1 );
                                
                                R_people.people_array{prev_index_p}.BoundingBox = [x_t, y_t, x_end_t-x_t+1, y_end_t-y_t+1];
                                
                                R_people.people_array{prev_index_p}.Area = body_prop(min_arg).Area+b_2.Area;
                                
                            end
                        end
                    end
                    
                    
                elseif count_el(i) > 1 && count_el(i) < 3
                    % more than one bounding box matched
                    
                    x_c = body_prop(vect(i)).Centroid(1);
                    y_c = body_prop(vect(i)).Centroid(2);
                    L = body_prop(vect(i)).MajorAxisLength;
                    theta = -deg2rad(body_prop(vect(i)).Orientation);
                    if theta < 0
                        theta = theta + pi;
                    end
                    
                    prev_ind = find(min_dis_vector(:,2) == vect(i) & ...
                        ~isinf(min_dis_vector(:,1)));
                    prev_ind_p = tmp_del(prev_ind);
                    %prev_ind = prev_ind(min_dis_vector(prev_ind, 1) <= 500*scale);
                    
                    if length(prev_ind) == 1
                        
                        del_index_of_body = [del_index_of_body; vect(i)];
                        R_people.people_array{prev_ind_p}.Centroid = body_prop(vect(i)).Centroid;
                        R_people.people_array{prev_ind_p}.Orientation = body_prop(vect(i)).Orientation;
                        R_people.people_array{prev_ind_p}.BoundingBox = body_prop(vect(i)).BoundingBox;
                        %R_people.people_array{prev_ind}.color_val = get_color_val(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                        R_people.people_array{prev_ind_p}.Area = body_prop(vect(i)).Area;
                        R_people.people_array{prev_ind_p}.temp_count = 0;
                        new_features = get_features(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                        R_people.people_array{prev_ind_p}.features = 0.5 * new_features + 0.5 *  R_people.people_array{prev_ind}.features;
                        continue;
                    end
                    
                    prev_people = [people_array_struct(prev_ind)];
                    list_centroid = [prev_people.Centroid];
                    [~,I] = sort(list_centroid(2,:), 'descend');
                    
                    thres_area = 0.9;
                    if length(prev_ind) == 2 && body_prop(vect(i)).Area < thres_area * sum([prev_people.Area])
                        % assuming two objects
                        [~, min_tmp_index] = min(min_dis_vector(prev_ind,1));
                        min_tmp_index = tmp_del(min_tmp_index);
                        % set matching to nearest body
                        del_index_of_body = [del_index_of_body; vect(i)];
                        
                        if check_max_overlap_people(body_prop(vect(i)).BoundingBox, R_people.people_array, min_tmp_index) > R_people.max_overlap
                            continue;
                        end
                        
                        R_people.people_array{min_tmp_index}.Centroid = body_prop(vect(i)).Centroid;
                        R_people.people_array{min_tmp_index}.Orientation = body_prop(vect(i)).Orientation;
                        R_people.people_array{min_tmp_index}.BoundingBox = body_prop(vect(i)).BoundingBox;
                        R_people.people_array{min_tmp_index}.temp_count = 0;
                        
                        [~, other_index] = max(min_dis_vector(prev_ind,1));
                        [other_sorted_distance, index_vector] = sort(dist(other_index,:));
                        if length(index_vector) > 1
                            other_matched_index = index_vector(2);
                            if isempty(find( min_dis_vector(:,2) == other_matched_index, 1 )) && other_sorted_distance(2) < R_people.min_allowed_dis
                                R_people.people_array{other_index}.Centroid = body_prop(other_matched_index).Centroid;
                                R_people.people_array{other_index}.Orientation = body_prop(other_matched_index).Orientation;
                                R_people.people_array{other_index}.BoundingBox = body_prop(other_matched_index).BoundingBox;
                                del_index_of_body = [del_index_of_body; other_matched_index];
                                R_people.people_array{other_index}.temp_count = 0;
                                
                            else
                                % temporary vanishing
                                R_people.people_array{other_index}.state = "temporary_vanishing";
                                %R_people.people_array{other_index}.temp_count = R_people.people_array{other_index}.temp_count+1;
                            end
                        else
                            % temporary vanishing
                            R_people.people_array{other_index}.state = "temporary_vanishing";
                            %R_people.people_array{other_index}.temp_count = R_people.people_array{other_index}.temp_count+1;
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
                            
                            p_ind = tmp_del(prev_ind(index));
                            
                            
                            % update bounding box
                            width = R_people.people_array{p_ind}.BoundingBox(3);
                            height = R_people.people_array{p_ind}.BoundingBox(4);
                            x = max(cent(1) - width / 2, 1);
                            y = max(cent(2) - height / 2, 1);
                            x_ = min(cent(1) + width / 2, size(im_r, 2));
                            y_ = min(cent(2) + height / 2, size(im_r, 1));
                            
                            wid = x_ - x + 1;
                            hei = y_ - y + 1;
                            
                            bbox = [x y wid hei];
                            
                            if check_max_overlap_people(bbox, R_people.people_array, p_ind) > R_people.max_overlap
                                continue;
                            end
                            
                            R_people.people_array{p_ind}.Centroid = cent;
                            
                            
                            R_people.people_array{p_ind}.BoundingBox = bbox;
                            
                            
                            offset = offset + L * kappa(index);
                        end
                        
                        del_index_of_body = [del_index_of_body; vect(i)];
                    end
                    
                end
            end
            
        end
    end
end

%% initial detection
for i = 1:numel(body_prop)
    
    if find(del_index_of_body == i, 1)
        continue;
    end
    
    if body_prop(i).Area < R_people.limit_init_area
        continue;
    end
    
    flag = 1;
    for j = 1:numel(R_people.people_array)
        if norm(body_prop(i).Centroid - R_people.people_array{j}.Centroid) < R_people.min_allowed_dis
            flag = 0;
            break;
        end
        
        if body_prop(i).Centroid(2) > R_people.people_array{j}.Centroid(2)
           flag = 0;
           break;
        end
        
    end
    
    if flag==0
        continue;
    end
    
    if check_max_overlap_people(body_prop(i).BoundingBox, R_people.people_array, -1) > R_people.max_overlap
        continue;
    end
    
    % check entrance
    if   body_prop(i).Centroid(1) < R_people.limit_init_x && ...
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
        
        [a, m] = calcAngleMag(im_flow_hsv, im_binary, body_prop(i).BoundingBox);
        
        
        Person = struct('Area', body_prop(i).Area, 'Centroid', ...
            body_prop(i).Centroid,'BoundingBox', body_prop(i).BoundingBox, ...
            'color_mat', zeros(40,20), 'label', R_people.label, 'counter', 1, ...
            'critical_del', -1000, 'color_count', 1, 'state', "unspec", ...
            'flow_angle', a, 'flow_mag', m, 'temp_count', 0, 'Orientation',body_prop(i).Orientation);
        Person.angle = zeros(1,5);
        R_people.label = R_people.label + 1;
        Person.color_mat(1,:) = get_color_val(im_r, body_prop(i).BoundingBox, im_binary);
        R_people.people_array{end+1} = Person;
        
        R_people.event{end+1} = sprintf('Person %d enters', Person.label);

    end
end

if debug_9
    f = figure;
    imshow(im_r);
    r = getrect;
    close(f);
    
    area = r(3)*r(4);%sum(sum(imcrop(im_binary, r)));
    bb = r;
    centroid = [r(1)+r(3)/2 r(2)+r(4)/2]';
    
    Person = struct('Area', area, 'Centroid', ...
        centroid,'BoundingBox',r, ...
        'color_mat', zeros(40,20), 'label', R_people.label, 'counter', 1, ...
        'critical_del', -1000, 'color_count', 1, 'state', "unspec", ...
        'flow_angle', 0, 'flow_mag', 20000, 'temp_count', 0, 'Orientation',0);
    Person.angle = zeros(1,5);
    R_people.label = R_people.label + 1;
    Person.color_mat(1,:) = get_color_val(im_r, r, im_binary);
    R_people.people_array{end+1} = Person;
    if debug_9 == 2
       debug_9 = 0; 
    end
    debug_9  = 0;
    %debug_9 = debug_9+1;
end

for i = 1:numel(R_people.people_array)
    
    
end

end