img = imread(fullfile(R_11.filename, sprintf('%04i.jpg', R_11.current_frame)));
im_c = imresize(img,scale);%original image
im_c = imrotate(im_c, R_11.rot_angle);

%im_c = lensdistort(im_c, R_11.R_bin.k_distort);
% load 9
R_11.R_peope.current_frame = R_11.current_frame;
R_11.R_bin.current_frame = R_11.current_frame;
R_11.R_bin.event = {};
R_11.R_people.event = {};

% flow image
try
    im_flow_all = imread(fullfile(R_11.flow_dir, sprintf('%04d_flow.jpg', R_11.current_frame)));
    im_flow_all = imrotate(im_flow_all, R_11.rot_angle);
    
    if check_bad_flow(im_flow_all, R_11.max_flow)
        im_flow_all = [];
    end
    
catch
    warning('Error reading file : %s',...
        fullfile(R_11.flow_dir, sprintf('%04d_flow.jpg', R_11.current_frame)));
    im_flow_all = [];
end

if R_11.current_frame  >= 1984
    1;
end

%% bin tracking
im_bins = im_c(R_11.R_bin.reg(3):R_11.R_bin.reg(4),R_11.R_bin.reg(1):R_11.R_bin.reg(2),:); % people region
%
im_b = im_bins;

if R_11.R_bin.check > 0
    if ~isempty(im_flow_all)
        im_flow_bin = im_flow_all(R_11.R_bin.reg(3):R_11.R_bin.reg(4),R_11.R_bin.reg(1):R_11.R_bin.reg(2),:);
        [R_11.R_bin, imb] = bin_detection_tracking_11(im_b, im_flow_bin, R_11.R_bin);
        
        %          R_11.R_bin.check = R_11.R_bin.check + R_11.R_bin.check_del;
        R_13.R_bin.check = R_13.R_bin.check - R_11.R_bin.check_del;
    else
        im_flow_bin = [];
    end
    
    %     im_b = lensdistort(im_bins, R_11.R_bin.k_distort);
end
%% people tracking
im_r = im_c(R_11.R_people.reg(3):R_11.R_people.reg(4),R_11.R_people.reg(1):R_11.R_people.reg(2),:); % people region

if R_11.R_people.check > 0
    if ~isempty(im_flow_all)
        im_flow_people = im_flow_all(R_11.R_people.reg(3):R_11.R_people.reg(4),R_11.R_people.reg(1):R_11.R_people.reg(2),:);
    else
        im_flow_people = [];
    end
    
    % detect people
    if ~isempty(im_flow_people)
        R_11.R_people.check_del = 0;
        R_11.R_people = people_detector_tracking_11(im_r, im_flow_people, R_11.R_people);
        
        R_11.R_people.check = R_11.R_people.check + R_11.R_people.check_del;
        R_13.R_people.check = R_13.R_people.check - R_11.R_people.check_del;
    end
end

%% display image

im = display_image_11(im_c, R_11);

%% pose detect and event
R_11.Event = poseEventDetection(im_c, R_11);


%% display pose
im = display_pose(im, R_11);

%% recent events
[im_text, R_11.recent_events] = display_event(R_11, size(im, 1));

im = cat(2, im, im_text);

% figure(11);
% imshow(im);
% drawnow;

%% increment frame
R_11.current_frame = R_11.current_frame + 1;
fprintf('Camera 11 frame : %04i\n', R_11.current_frame);

%warning('off','last');
if R_11.write
    %     writeVideo(R_11.writer1, im_11_b);
    %     writeVideo(R_11.writer2, im_11_p);
    writeVideo(R_11.writer, im);
end