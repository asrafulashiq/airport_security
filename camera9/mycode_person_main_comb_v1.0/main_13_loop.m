R_13.current_frame = R_11.current_frame + 20;

img = imread(fullfile(R_13.filename, sprintf('%04i.jpg', R_13.current_frame)));
im_c = imresize(img,scale);%original image
im_c = imrotate(im_c, R_13.rot_angle);

% flow image
try
    im_flow_all = imread(fullfile(R_13.flow_dir, sprintf('%04d_flow.jpg', R_13.current_frame)));
    im_flow_all = imrotate(im_flow_all, R_13.rot_angle);
catch
    warning('Error reading file : %s',...
        fullfile(R_13.flow_dir, sprintf('%04d_flow.jpg', R_13.current_frame)));
    im_flow_all = [];
end

if R_13.current_frame  >= 1984
    1;
end
%% bin tracking

% initial bin detection

%% bin tracking
im_b = im_c(R_13.R_bin.reg(3):R_13.R_bin.reg(4),R_13.R_bin.reg(1):R_13.R_bin.reg(2),:); % people region

if R_13.R_bin.check > 0
    
    if abs( R_11.R_bin.check_del) > 0
        
        R_13.R_bin.bin_array{end+1} = R_11.R_bin.bin_seq{end};
        tracker = R_11.R_bin.bin_seq{end}.tracker;%BACF_tracker(im, bin_array{i}.BoundingBox);
        new_pos = [108, 58];%bin_array{i}.Centroid ;
        tracker = tracker.setPos(new_pos,[]);
        R_13.R_bin.bin_array{end}.tracker = tracker;
        R_11.R_bin.check_del = 0;
    end
    
    
    R_13.R_bin = bin_detection_tracking_13(im_b, im_flow_bin, R_13.R_bin);
    
    % a brute force, avoid it in future
    
    R_13.R_bin.check = R_13.R_bin.check + R_13.R_bin.check_del;
end
%% people tracking

if R_13.R_people.check > 0
    im_r = im_c(R_13.R_people.reg(3):R_13.R_people.reg(4),R_13.R_people.reg(1):R_13.R_people.reg(2),:); % people region
    
    if ~isempty(im_flow_all)
        im_flow = im_flow_all(R_13.R_people.reg(3):R_13.R_people.reg(4),R_13.R_people.reg(1):R_13.R_people.reg(2),:);
    else
        im_flow = [];
    end
    
    
    if abs( R_11.R_people.check_del) > 0
        
        R_13.R_people.stack_of_people{end+1} = R_11.R_people.people_seq{end};
        
        R_11.R_people.check_del = 0;
    end
    
    
    % detect people
    R_13.R_people.check_del = 0;
    R_13.R_people = people_detector_tracking_13(im_r, im_flow, R_13.R_people);
    R_13.R_people.check = R_13.R_people.check + R_13.R_people.check_del;
    disp('');
end

%% display image

img = display_image(im_c, R_13, 0);

figure(13);
imshow(img);

%% increment frame
R_13.current_frame = R_13.current_frame + 1;
fprintf('frame : %04i\n', R_13.current_frame);

%warning('off','last');
if R_13.write
    writeVideo(R_13.writer, img);
end