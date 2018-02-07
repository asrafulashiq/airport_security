function R_bin = bin_detection_tracking(im, im_flow, R_bin)


im_flow_g = rgb2gray(im_flow);
im_flow_hsv = rgb2hsv(im_flow);

im_filtered = imgaussfilt(im_flow_g, 4);
im_tmp = im_filtered;
im_filtered(im_filtered < R_bin.threshold_img) = 0;

% close operation for the image
se = strel('disk',5);
im_closed = imclose(im_filtered,se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');
im_binary_orig = im_binary;

figure(2);imshow(im_binary);
figure(3); imshow(im_flow);

%% initial bin detection
% remove previous bins region
for i = 1:numel(R_bin.bin_array)
    bb = R_bin.bin_array{i}.BoundingBox;
    r = [max(bb(2),1) min(bb(2)+bb(4)-1,size(im_binary,1)) max(bb(1),1) min(bb(1)+bb(3)-1, size(im_binary,2))];
    im_binary(r(1):r(2), r(3):r(4)) = 0;
end

% check bad flow
im_tmp(im_tmp < 5) = 0;
im_tmp = logical(im_tmp);
if sum(im_tmp(:)) > 60000
    disp('BAD FLOW!!');
    return;
end

%% blob analysis
cpro_r1 = regionprops(im_binary,'all'); % extract parameters
body_prop = cpro_r1([cpro_r1.Area] > R_bin.limit_area & ...
    [cpro_r1.Area] < R_bin.limit_max_area & [cpro_r1.MinorAxisLength] > 120 & ...
    [cpro_r1.MajorAxisLength]./[cpro_r1.MinorAxisLength] > 1.1 & ...
    [cpro_r1.MajorAxisLength]./[cpro_r1.MinorAxisLength] < 1.8);

for i = 1:numel(body_prop)
    
    flag = 1;
    
    for j = 1:numel(R_bin.bin_array)
        if norm(R_bin.bin_array{j}.Centroid - body_prop(i).Centroid) < R_bin.limit_distance
            flag = 0;
            break;
        end
    end
    
    if flag==0 || body_prop(i).Centroid(2) > R_bin.limit_init_y
        continue;
    end
    
    % ratio of total area /  number of pixels
    rect_area = body_prop(i).BoundingBox(3)*body_prop(i).BoundingBox(4);
    
    if rect_area / body_prop(i).Area > R_bin.area_ratio
        continue;
    end
    
    % get color
    imcrop_rgb = imcrop(im .* uint8(im_binary), body_prop(i).BoundingBox);
    imcropped = rgb2gray(imcrop_rgb);
    color = sum(imcropped(:)) / sum(imcropped(:) > 0);
    if abs(color - 190) > 90
        fprintf('color value : %d\n', color);
        continue;
    end
    
    Bin = body_prop(i);
    Bin.tracker = [];
    Bin.label = R_bin.label;
    R_bin.label = R_bin.label + 1;
    
    R_bin.bin_array{end+1} = Bin;
    
end

%% tracking
bin_array = R_bin.bin_array;

del_exit = [];
for i = 1:numel(bin_array)
    
    strt = 0;
    if isempty(bin_array{i}.tracker)
        % init tracker
        strt = 1;
        tracker = BACF_tracker(im, bin_array{i}.BoundingBox);
    else
        tracker = bin_array{i}.tracker;
%         x = imcrop(im_binary_orig, bin_array{i}.BoundingBox);    
%         area = sum(x(:));
%         if area > R_bin.limit_min_area
%            bin_array{i}.Area = area; 
%         end
    end
    
    [bin_array{i}.tracker, bb] = tracker.runTrack(im);
    bin_array{i}.BoundingBox = bb;
    bin_array{i}.Centroid = [bb(1)+bb(3)/2 bb(2)+bb(4)/2]';
    
    % check flow
%     if strt == 0
%         bbf = bin_array{i}.BoundingBox;
%         rf = [max(bbf(2)-30,1) min(bbf(2)+bbf(4)-1+30,size(im_binary,1)) ...
%             max(bbf(1),1) min(bbf(1)+bbf(3)-1, size(im_binary,2))];
%         im_crop = im_binary_orig(rf(1):rf(2), rf(3):rf(4));
%         rat_prev = bin_array{i}.Area / bin_array{i}.Perimeter - R_bin.solidness_ratio;
%         fprintf('solid ratio : %.2f\n', rat_prev);
%         
%         if sum(im_crop(:)) > R_bin.limit_area
%             cpro_reg = regionprops(im_crop,'Centroid','Area','BoundingBox', ...
%                 'MajorAxisLength', 'MinorAxisLength', 'Perimeter'); % extract parameters
%             if numel(cpro_reg)>=1
%                 region = cpro_reg([cpro_reg.Area]==max([cpro_reg.Area]));
%                 
%                 dim = sort(region.BoundingBox(3:4));
%                 
%                 %rat_prev = bin_array{i}.Area / bin_array{i}.Perimeter - R_bin.solidness_ratio;
%                 rat_now = region.Area / region.Perimeter - R_bin.solidness_ratio;
%                 
%                 if region.Area > R_bin.limit_area && abs(rat_now) < 4 && ...
%                         dim(2) / dim(1) > 1.10 && dim(2) / dim(1) < 1.4  && ...
%                         norm(region.BoundingBox-bin_array{i}.BoundingBox) > 60 && ...
%                         region.Area < R_bin.limit_area2 && ...
%                         region.MajorAxisLength/region.MinorAxisLength > 1.28 && ...
%                         region.MajorAxisLength/region.MinorAxisLength < 1.38
%                     
%                     region.BoundingBox(1:2) = region.BoundingBox(1:2) + [rf(3) rf(1)];
%                     region.Centroid = region.Centroid + [rf(3) rf(1)];
%                     region.tracker = BACF_tracker(im, region.BoundingBox);
%                     region.label = bin_array{i}.label;
%                     bin_array{i} = region;
%                     
%                     fprintf('tracker initiated for label : %d\n', region.label);
%                     
%                 end
%                 
%             end
%         end
%     end
    

    
    % detect exit
    
    if bin_array{i}.Centroid(2) > R_bin.limit_exit_y
        R_bin.bin_seq{end+1} = bin_array{i};
        del_exit(end+1) = i;
    end
end
bin_array(del_exit) = [];

R_bin.bin_array = bin_array;

end