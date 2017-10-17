function [people_seq, people_array] = a_peopletracking2(im_c,R_dropping,...
                                        R_belt,people_seq,people_array, bin_array)
                                    
%% region 1 extraction                                   
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);

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

im_draw = im_r;
body_prop = [];
for i = 1:size(cpro_r1, 1)
    if cpro_r1(i).Area > 20000
        body_prop = [body_prop; cpro_r1(i)];
        im_draw = insertShape(im_draw, 'Rectangle', int32(cpro_r1(i).BoundingBox), 'LineWidth', 10);
    end
end

%figure(2); imshow(im_draw);

%% track previous detection
%%%% TODO

for i = 1 : size(people_array, 2)
    people_prev = people_array{i};
    
    % find nearest bbox which has closest area with previous people;
    % if no bbox there, find part of bbox to match;
    % take decision whether new bbox is 'consistant' or 'temporary';
    % if 'consistant' then update fields of the people struct, and 
    
    
end
    
%% initial detection
% Do detection & tracking first

for i = 1 : size(body_prop, 1)
    
    % TODO:::check if bbox area is enugh to detect a person
    
    % create new person struct
    r1_label = r1_label + 1; % new person label added
    Person = struct('Area', body_prop(i).Area, 'Centroid', body_prop(i).Centroid, ...
        'Orientation', body_prop(i).Orientation, 'BoundingBox', body_prop(i).BoundingBox, ...
        'label', r1_label);
    people_array{end+1} = Person;
    
    % TODO:::determine whether person is 'consistant' or 'temporary'.
    % if 'consistant', calculate feature vector; else do nothing.
    % update image_binary fill 
    
end


end