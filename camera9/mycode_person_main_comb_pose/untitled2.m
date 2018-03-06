%     if numel(R_people.people_array) ~= 0
        
        tmp_del = boolean(ones(1, numel(R_people.people_array)));
        
        for i = 1:numel(R_people.people_array)
            
            % if flow magnitude is less than particular value, don't update
            if R_people.people_array{i}.flow_mag < R_people.limit_flow_mag
                tmp_del(i) = false;
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
            for i = numel(people_array_struct)
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
                    prev_index_p = min_dis_vector(:,2) == vect(i);
                    prev_index = tmp_del(prev_index_p);
                    if isinf(min_dis_vector(prev_index_p, 1)) || ...
                            ~ ( body_prop(min_arg).Area < 2*R_people.people_array{prev_index}.Area && ...
                            (body_prop(min_arg).Area > 0.5 * R_people.people_array{prev_index}.Area && body_prop(min_arg).Centroid(1) < R_people.half_x ...
                                    && body_prop(min_arg).Area > R_people.limit_init_area  ) || ...
                            (body_prop(min_arg).Area > 0.3 * R_people.people_array{prev_index}.Area && body_prop(min_arg).Centroid(1) >= R_people.half_x))                       
                        continue;
                    end
                    
                    if min_dis_vector(prev_index_p, 1) > R_people.min_allowed_dis
                        continue;
                    end
                    
                    min_arg = vect(i);
                    
                    
                    if body_prop(min_arg).BoundingBox(3)>R_people.limit_max_width || body_prop(min_arg).BoundingBox(4)>R_people.limit_max_height
                        %&& R_people.people_array{i}.state ~= "temp_disappear" %  body_prop(min_arg).Area > 1.3 * R_people.people_array{i}.Area
                        % divide area and match
                        [bbox_matched, ~, centroid] = match_people_bbox(im_r, im_binary, R_people.people_array{prev_index});
                        
                        if ~isempty(bbox_matched)
                            del_index_of_body = [del_index_of_body; min_arg];
                            R_people.people_array{prev_index}.Centroid = centroid'; %ait_centroid(im_binary, bbox_matched);
                            R_people.people_array{prev_index}.BoundingBox = bbox_matched;
                            R_people.people_array{prev_index}.temp_count = 0;
                            
                            cnt = R_people.people_array{prev_index}.color_count;
                            R_people.people_array{prev_index}.color_mat(mod(cnt,40)+1,:) = get_color_val(im_r, ...
                                R_people.people_array{prev_index}.BoundingBox, im_binary);
                            R_people.people_array{prev_index}.color_count = R_people.people_array{prev_index}.color_count + 1;
                        end
                        continue;
                    end
                    
                    % check mahal distance
                    cnt = R_people.people_array{prev_index}.color_count;
                    color = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary );
%                     if cnt >= 40
%                         dis = mahal( color,  R_people.people_array{prev_index}.color_mat);
%                         fprintf('Distance (mahal) : %f\n', dis);
%                     else
%                         dis = pdist2(color, mean(R_people.people_array{prev_index}.color_mat(1:cnt,:), 1), 'correlation' );
%                         fprintf('Distance (corr) : %f\n', dis);
%                     end
                    
                    
                    R_people.people_array{prev_index}.Centroid = body_prop(min_arg).Centroid;
                    del_index_of_body = [del_index_of_body; min_arg];
                    
                    R_people.people_array{prev_index}.BoundingBox = body_prop(min_arg).BoundingBox;
%                     R_people.people_array{prev_index}.color_val = get_color_val(im_r, body_prop(min_arg).BoundingBox, im_binary);
                    R_people.people_array{prev_index}.Area = 0.7 * body_prop(min_arg).Area + 0.3 * R_people.people_array{prev_index}.Area;
                    
                    cnt = R_people.people_array{prev_index}.color_count;
                    R_people.people_array{prev_index}.color_mat(mod(cnt,100)+1,:) = get_color_val(im_r, ...
                        R_people.people_array{prev_index}.BoundingBox, im_binary);
                    R_people.people_array{prev_index}.color_count = R_people.people_array{prev_index}.color_count + 1;
                    
                    
                    % check second minimum value
                    if length(dist(i,:)) > 1
                        
                        all_dist = sort(dist(i,:));
                        second_min_index = find(dist(i,:)==all_dist(2));
                        if ~isinf(all_dist(2))  && all_dist(2) < 200 &&  isempty(find(min_dis_vector==second_min_index, 1))
                            
                            total_area = body_prop(second_min_index).Area + body_prop(min_arg).Area;
                            if total_area < 2 * R_people.people_array{prev_index}.Area
                                bb = body_prop(second_min_index).BoundingBox;
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
                    
                    
                else
                    % more than one bounding box matched
                    
                    x_c = body_prop(vect(i)).Centroid(1);
                    y_c = body_prop(vect(i)).Centroid(2);
                    L = body_prop(vect(i)).MajorAxisLength;
                    theta = -deg2rad(body_prop(vect(i)).Orientation);
                    if theta < 0
                        theta = theta + pi;
                    end
                    
                    prev_ind_p = find(min_dis_vector(:,2) == vect(i) &  ~isinf(min_dis_vector(:,1)));
                    
%                     prev_ind = prev_ind(min_dis_vector(prev_ind, 1) <= 500*scale);
                    prev_ind = tmp_del(prev_ind_p);

                    
                    if length(prev_ind) == 1
                        
                        del_index_of_body = [del_index_of_body; vect(i)];
                        R_people.people_array{prev_ind}.Centroid = body_prop(vect(i)).Centroid;
                        R_people.people_array{prev_ind}.Orientation = body_prop(vect(i)).Orientation;
                        R_people.people_array{prev_ind}.BoundingBox = body_prop(vect(i)).BoundingBox;
%                         R_people.people_array{prev_ind}.color_val = get_color_val(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                        R_people.people_array{prev_ind}.Area = body_prop(vect(i)).Area;
                        R_people.people_array{prev_ind}.temp_count = 0;
                        new_features = get_features(im_r, body_prop(vect(i)).BoundingBox, im_binary);
                        R_people.people_array{prev_ind}.features = 0.5 * new_features + 0.5 *  R_people.people_array{prev_ind}.features;
                        
                        %                         cnt = R_people.people_array{prev_index}.color_count;
                        %                         R_people.people_array{prev_index}.color_mat(mod(cnt,100)+1,:) = get_color_val(im_r, ...
                        %                             R_people.people_array{prev_index}.BoundingBox, im_binary);
                        %                         R_people.people_array{prev_index}.color_count = R_people.people_array{prev_index}.color_count + 1;
                        continue;
                    end
                    
                    prev_people = [people_array_struct(prev_ind_p)];
                    list_centroid = [prev_people.Centroid];
                    [~,I] = sort(list_centroid(2,:), 'descend');
                    
                    thres_area = 0.9;
                    if length(prev_ind) == 2 && body_prop(vect(i)).Area < thres_area * sum([prev_people.Area])
                        % assuming two objects
                        [~, min_tmp_index] = min(min_dis_vector(prev_ind_p,1));
                        
                        % set matching to nearest body
                        del_index_of_body = [del_index_of_body; vect(i)];
                        R_people.people_array{min_tmp_index}.Centroid = body_prop(vect(i)).Centroid;
                        R_people.people_array{min_tmp_index}.Orientation = body_prop(vect(i)).Orientation;
                        R_people.people_array{min_tmp_index}.BoundingBox = body_prop(vect(i)).BoundingBox;
                        R_people.people_array{min_tmp_index}.temp_count = 0;
                        
                        [~, other_index] = max(min_dis_vector(prev_ind_p,1));
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

