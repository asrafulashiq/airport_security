%%
if ~isempty(R_people.people_array) && ~isempty(list_bbox)
    
    for i = 1:size(R_people.people_array,2)
        
        % detect exit
        person = R_people.people_array{i};
        
        if person.Centroid(1) > R_people.limit_exit_x && ...
                person.Centroid(2) >  R_people.limit_exit_y
            del_exit(end+1) = i;
        end
        
        if person.Centroid(1) > R_people.limit_exit_x2 && ...
                person.Centroid(2) >  R_people.limit_exit_y2 && ...
                mean(person.angle) > 30 && mean(person.angle) < 180 && ...
                person.Area < R_people.limit_exit_max_area
            del_exit(end+1) = i;
        end
    R_people.people_array{i}.counter = R_people.people_array{i}.counter + 1;
    end
    
    R_people.people_array(del_exit) = [];
    
    
    people_array_struct = [R_people.people_array{:}];
    % determine minimum distance
    min_dis_vector = [];
    if ~isempty(R_people.people_array)
        
        dist = pdist2(double([people_array_struct.Centroid]'), double(list_bbox));
        for i = numel(R_people.people_array)
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
                
                if body_prop(min_arg).BoundingBox(3)>R_people.limit_max_width || body_prop(min_arg).BoundingBox(4)>R_people.limit_max_height
                    %&& R_people.people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * R_people.people_array{i}.Area
                    % divide area and match
                    [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, R_people.people_array{prev_index}, flow);
                    
                    if ~isempty(bbox_matched)
                        del_index_of_body = [del_index_of_body; min_arg];
                        R_people.people_array{prev_index}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                        R_people.people_array{prev_index}.BoundingBox = bbox_matched;
                        R_people.people_array{prev_index}.temp_count = 0;
                    end
                    continue;
                end
                
                
                
                R_people.people_array{prev_index}.Centroid = body_prop(min_arg).Centroid;
                del_index_of_body = [del_index_of_body; min_arg];
                
                R_people.people_array{prev_index}.BoundingBox = body_prop(min_arg).BoundingBox;
                R_people.people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                R_people.people_array{prev_index}.Area = body_prop(min_arg).Area;
                
                % check second minimum value
                if length(dist(i,:)) > 1
                    
                    all_dist = sort(dist(i,:));
                    second_min_index = find(dist(i,:)==all_dist(2));
                    if ~isinf(all_dist(2))  && all_dist(2) < 200 &&  isempty(find(min_dis_vector==second_min_index, 1))
                                            
                        total_area = body_prop(second_min_index).Area + body_prop(min_arg).Area;
                        if total_area < 2 * R_people.people_array{prev_index}.Area
                            bb = body_prop(second_min_index).BoundingBox;
                            total_flow = sum(sum( flow.Magnitude(bb(2):bb(2)+bb(4)-1, bb(1):bb(1)+bb(3)-1)));
                            if total_flow > 1000
                                % pass
                                
                                b_2 = body_prop(second_min_index);
                                b_1 = body_prop(min_arg);
                                
                                R_people.people_array{prev_index}.Centroid = (body_prop(min_arg).Centroid*body_prop(min_arg).Area + ...
                                    body_prop(second_min_index).Centroid * body_prop(second_min_index).Area) / ...
                                    (body_prop(second_min_index).Area + body_prop(min_arg).Area);
                                
                                del_index_of_body = [del_index_of_body; second_min_index];
                                
                                % bbox
                                x_t = min( b_2.BoundingBox(1), b_1.BoundingBox(1) );
                                y_t = min( b_2.BoundingBox(2), b_1.BoundingBox(2) );
                                
                                x_end_t = max( b_2.BoundingBox(1)+b_2.BoundingBox(3)-1, b_1.BoundingBox(1)+b_1.BoundingBox(3)-1 );
                                y_end_t = max( b_2.BoundingBox(2)+b_2.BoundingBox(4)-1, b_1.BoundingBox(2)+b_1.BoundingBox(4)-1 );
                                
                                R_people.people_array{prev_index}.BoundingBox = [x_t, y_t, x_end_t-x_t+1, y_end_t-y_t+1];
                                
                                R_people.people_array{prev_index}.Area = body_prop(min_arg).Area+b_2.Area;
                                
                                
                            end
                        end
                    end
                end
                
                R_people.people_array{prev_index}.Orientation = body_prop(min_arg).Orientation;
                R_people.people_array{prev_index}.temp_count = 0;
                new_features = get_features(im_r, body_prop(min_arg).BoundingBox, im_binary);
                R_people.people_array{prev_index}.features = 0.5 * new_features + 0.5 * R_people.people_array{prev_index}.features;
                
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
                    R_people.people_array{prev_ind}.Centroid = body_prop(vect(i)).Centroid;
                    R_people.people_array{prev_ind}.Orientation = body_prop(vect(i)).Orientation;
                    R_people.people_array{prev_ind}.BoundingBox = body_prop(vect(i)).BoundingBox;
                    R_people.people_array{prev_ind}.color_val = get_color_val(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    R_people.people_array{prev_ind}.Area = body_prop(vect(i)).Area;
                    R_people.people_array{prev_ind}.temp_count = 0;
                    new_features = get_features(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                    R_people.people_array{prev_ind}.features = 0.5 * new_features + 0.5 *  R_people.people_array{prev_ind}.features;
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
                            R_people.people_array{other_index}.temp_count = R_people.people_array{other_index}.temp_count+1;
                        end
                    else
                        % temporary vanishing
                        R_people.people_array{other_index}.state = "temporary_vanishing";
                        R_people.people_array{other_index}.temp_count = R_people.people_array{other_index}.temp_count+1;
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
                        R_people.people_array{prev_ind(index)}.Centroid = cent;
                        
                        % update bounding box
                        width = R_people.people_array{prev_ind(index)}.BoundingBox(3);
                        height = R_people.people_array{prev_ind(index)}.BoundingBox(4);
                        x = max(cent(1) - width / 2, 1);
                        y = max(cent(2) - height / 2, 1);
                        x_ = min(cent(1) + width / 2, size(im_r, 2));
                        y_ = min(cent(2) + height / 2, size(im_r, 1));
                        
                        wid = x_ - x + 1;
                        hei = y_ - y + 1;
                        
                        bbox = [x y wid hei];
                        R_people.people_array{prev_ind(index)}.BoundingBox = bbox;
                        
                        offset = offset + L * kappa(index);
                    end
                    
                    del_index_of_body = [del_index_of_body; vect(i)];
                end
                
            end
        end
        
    end
    
end


%%
for i=1:numel(body_prop)
    for j=1:numel(R_people.people_array)

        if norm(body_prop(i).Centroid - R_people.people_array{j}.Centroid) < R_people.min_allowed_dis
            
            if  body_prop(i).Area < 2*R_people.people_array{j}.Area && ...
                    ( (body_prop(i).Area > 0.5 * R_people.people_array{j}.Area && body_prop(i).Centroid(1) < R_people.limit_half_x) || ...
                    (body_prop(i).Area > 0.4 * R_people.people_array{j}.Area && body_prop(i).Centroid(1) >= R_people.limit_half_x))
                
                update = true;
                
                % color
                color = get_color_val(im_r, body_prop(i).BoundingBox, im_binary);
                cnt = R_people.people_array{j}.color_count;
                if cnt <= 100
                    R_people.people_array{j}.color_mat(cnt,:) = color;
                    R_people.people_array{j}.color_count = cnt + 1;
                else
                    % calculate mahalanobis distance between colorb histogram
                    dis = mahal(color, R_people.people_array{j}.color_mat);
                    
                    if dis > 1
                        % don't update it
                        update = false;
                    else
                        R_people.people_array{j}.color_mat(mod(cnt,100)+1,:) = color;
                    end
                end
                
                
                
                % update
                if update
                    R_people.people_array{j}.Centroid = body_prop(i).Centroid;
                    R_people.people_array{j}.Area = 0.5 * (body_prop(i).Area + R_people.people_array{j}.Area);
                    R_people.people_array{j}.BoundingBox = body_prop(i).BoundingBox;
                    R_people.people_array{j}.angle(mod( R_people.people_array{j}.counter,5)+1) = body_prop(i).angle;
                end
                
                
            else
                1;
            end
            
            del_index_of_body(end+1) = i;
            break;
        end
    end
end

%% bin detection

global debug;
global scale;

thr = 0.8;

im_back = R_bin.im_back;

%% Set up parameters
threshold = R_bin.threshold;
dis_exit_y = R_bin.dis_exit_y * scale;%2401520;

%% Preprocessing
im_actual = im;

im_gray = rgb2gray(im_actual);
im_back_gray = rgb2gray(im_back);
im_r4 = abs(im_gray-im_back_gray) + abs(im_back_gray - im_gray);

imr4t = im_r4;

pt2 = [];

for i = 1: (size(imr4t,1))
    pt2(i) = ( mean( imr4t(i,:) ) );
end

loc = find( pt2 > threshold);
if isempty(loc)
    return;
end

loc_something = [ loc(1) loc(end) ];

I = uint8(zeros(size(im_actual,1), size(im_actual,2)));
I(loc,:) = rgb2gray(im_actual(loc,:,:));


%% match initial

r_tall_val = 160;
r_tall_width = floor(220 * scale);
r_tall_bin = create_rect(r_tall_width, 5, r_tall_val);

% create rectangular wide pulse
r_wide_val = 140;
r_wide_width = floor(280 * scale);
r_wide = create_rect(r_wide_width, 5, r_wide_val);

r_tall = r_tall_bin;

coef_aray = [];
loc_array = [];

if isempty(loc_something)
    loc_something = [1 size(I,1)/2];
end

if loc_something(2) > size(I,1)*.6
    loc_something(2) = size(I,1)*.6;
end

%loc_end = loc_something(2) - length(r_tall) + 1;

if abs(loc_something(2) - loc_something(1)) <= thr * length(r_tall)
    return;
end

if abs(loc_something(2) - loc_something(1))> thr * length(r_tall) && loc_something(2)-loc_something(1) < length(r_tall)
    r_tall = ones(1, int64(loc_something(2) - loc_something(1)+1) );
    r_tall(1:3) = 0; r_tall(end-2:end) = 0;
    r_tall = r_tall * r_tall_val;
end


limit_std = 30;
for i = loc_something(1): ( loc_something(2) -  length(r_tall) + 1 )
    I_d = calc_intens(I(:, 1:int32(size(I,2)*0.7)), [ i i+length(r_tall)-1 ]);
    %coef = sum(abs( r_tall - I_d )) / length(r_tall);
    coef = calc_coef_w(r_tall, I_d);
    
    if std(I_d(20:end-20)) > limit_std
        continue;
    end
    
    if coef > 50
        continue;
    end
    
    
    centre = (i + i+length(r_tall)-1) / 2;

    flag = 0;
    for j=1:numel(R_bin.bin_array)      
        if abs(centre - R_bin.bin_array{j}.Centroid(2)) < R_bin.limit_distance
            flag = 1;
            break;
        end
    end
    if flag == 1
       continue; 
    end

    coef_aray = [ coef_aray coef ];
    loc_array = [loc_array i];
    
end

if isempty(coef_aray)
    return;
end

[ min_val , min_index] = min(coef_aray);
min_loc = loc_array(min_index);

loc_end = min_loc + length(r_tall)-1;
height = loc_end - min_loc + 1;
T_ = I( min_loc: min_loc+length(r_tall)-1, : );
Loc = [  size(I,2)/2  min_loc+length(r_tall)/2-1 ];

%%% draw
if debug
    plot( min_loc:loc_end, r_tall );
    %disp("min loc :"+min_loc);
    %disp("min value :"+min_val);
end


Bin = struct( ...
    'Area',size(T_,1)*size(T_,2), 'Centroid', Loc', ...
    'BoundingBox', [1 min_loc size(I,2) height ], ...
    'limit', [ min_loc loc_end ] ,...
    'image',I( min_loc : loc_end , : ), ...
    'belongs_to', -1, ...
    'label', -1, 'tracker', [],...
    'in_flag', 1, 'r_val', r_tall_val, 'bin_or',"tall", ...
    'state', "empty", 'count', 1, ...
    'std', std(calc_intens(I, [min_loc loc_end]), 1), 'destroy', false ...
    );

R_bin.bin_array{end+1} = Bin;

