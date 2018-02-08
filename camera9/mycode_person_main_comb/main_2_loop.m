
R_2.current_frame = R_9.current_frame;

img = imread(fullfile(R_2.filename, sprintf('%04i.jpg', R_2.current_frame)));
im_c = imresize(img,scale);%original image
im_c = imrotate(im_c, R_2.rot_angle);

% flow image
try
    im_flow_all_box = imread(fullfile(R_2.flow_dir, sprintf('%04d_flow.jpg', R_2.current_frame)));
    im_flow_all = imrotate(im_flow_all_box, R_2.rot_angle);
    if detect_bad_flow(im_flow_all, R_2.max_flow_thres) == false
        im_flow_all = [];
    end
catch
    warning('Error reading file : %s',...
        fullfile(R_2.flow_dir, sprintf('%04d_flow.jpg', R_2.current_frame)));
    im_flow_all = [];
end

if R_2.current_frame  >= 1984
    1;
end

%% people tracking
im_r = im_c; % people region

if ~isempty(im_flow_all)
    im_flow_people = im_flow_all;
    [R_2.R_people, R_9.R_people] = people_detector_tracking_camera_2(im_r, im_flow_people, R_2.R_people, R_9.R_people);
    
else
    im_flow_people = [];
    disp('BAD FLOW : Camera 2');
end
    


im = display_image_2(im_c, R_2);

%% increment frame
R_2.current_frame = R_2.current_frame + 1;
%fprintf('frame : %04i\n', R_2.current_frame);

if R_2.write
    writeVideo(R_2.writer, im);
end





