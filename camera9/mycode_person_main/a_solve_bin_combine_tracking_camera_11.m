%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable
global debug;
global debug_people_11;
global debug_people_13;
debug_people_11 = true;
debug_people_13 = true;

debug = true;
tmp = 0;

debug_people = false;
global scale;
scale = 0.5;
global associate;
associate = false;
global associate_13;
associate_13 = true;

%%
show_image = false;
is_write_video = false;

my_decision = 0;
global k_distort_11;
k_distort_11 = -0.24;

global k_distort_13;
k_distort_13 = -0.20;

diff_frame_sec = 0; % camera 13 is 5 second behind

%% load video data
% file for input video

all_file_nums = [ "7A"];%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    R_11.input_filename = fullfile('..',file_number, 'camera11.mp4');
    R_13.input_filename = fullfile('..',file_number, 'camera13.mp4');
    
    if ~exist(R_11.input_filename)
        R_11.input_filename = fullfile('..',file_number, 'Camera_11.mp4');
        if ~exist(R_11.input_filename)
            error('file does not exist');
        end
    end
    
    v_11 = VideoReader(R_11.input_filename);
    
    R_com_info = [];
    
    if associate_13
        v_13 = VideoReader(R_13.input_filename);
        R_com_info.check_13 = 0;  
        R_com_info.check_11 = 0;
    end
    
    %% the file for the outputvideo
    if is_write_video
        output_filename = fullfile('..',file_number, ['output11_' file_number '.avi']);
        outputVideo = VideoWriter(output_filename);
        outputVideo.FrameRate = v_11.FrameRate;
        open(outputVideo);
    end
    
    %% file to save variables
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars2.mat']);
    
    start_fr = 4450;
    
    %% Camera 11
    %% region setting,find region position
    
    % Region1: droping bags
    R_11.R_dropping.r1 = [570 1080 286 1800] * scale; %r1;%[103 266 61 436];
    % Region4: Belt
    R_11.R_belt.r4 = [230 550 150-140 1920] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_11.R_belt.r4 = r4;
    R_11.rot_angle = 90;
    %% Region background
    counter = 0;
    im_back = 0;
    
    while hasFrame(v_11) && counter < 10
        im_frame = readFrame(v_11);
        im_back = im_back + double(im_frame);
        counter = counter + 1;
    end
    R_11.im_background = im_back / (counter);
    R_11.im_background = uint8(R_11.im_background);
    
    %load('imback.mat','R_11.im_background');
    R_11.im_background = imresize(R_11.im_background, scale);
    R_11.im_background = imrotate(R_11.im_background, R_11.rot_angle);
    
    R_11.im_background = lensdistort(R_11.im_background, k_distort_11); % solve radial distortion
    
    R_11.R_belt.flow = [];
    R_11.R_dropping.flow = [];
    
    R_11.R_belt.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    R_11.R_dropping.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    
    
    R_11.R_belt.im_r4_p = R_11.im_background(R_11.R_belt.r4(3):R_11.R_belt.r4(4),R_11.R_belt.r4(1):R_11.R_belt.r4(2),:);
    R_11.R_dropping.im_r1_p = R_11.im_background(R_11.R_dropping.r1(3):R_11.R_dropping.r1(4),R_11.R_dropping.r1(1):R_11.R_dropping.r1(2),:);
    %R_11.R_dropping.im_r1_p = lensdistort(R_11.R_dropping.im_r1_p, k_distort_11);
    
    % object information for each region
    R_11.R_dropping.r1_obj = [];
    %     R_11.R_belt.r4_obj = [];
    % sequence of bin and people
    R_11.people_seq = [];
    R_11.bin_seq = {};
    R_11.bin_array={};
    R_11.people_array = {};
    % object count for each region
    R_11.R_dropping.r1_cnt = 0;
    R_11.R_dropping.r1_lb = 0;
    %R_11.R_belt.r4_cnt = 0;
    % object Labels
    R_11.R_dropping.label = 1;
    R_11.R_belt.label = 1;
    starting_index = -1;
    
    R_c9 = [];
    if associate   % load camera 9 information
        load(file_to_save);
        R_c9.bin_seq = bin_seq;
        R_c9.frame_count = frame_count;
        R_c9.people_seq = [people_seq{:}];
        R_c9.R_belt = R_belt;
        R_c9.R_dropping = R_dropping;
        R_c9.start_fr = start_fr;
    end
    
    % for debug
    if associate
        R_11.R_belt.label = 3;
        R_11.R_dropping.label = 2;
    end
    
    R_11.R_dropping.prev_body = [];
    
    %% the parameter for the start frame and end frame
    end_f = v_11.Duration * v_11.FrameRate ; %15500;
    v_11.CurrentTime = start_fr / 30;%v_11.FrameRate ;
    
    %% Camera 13
    if associate_13
        
        %% region setting,find region position
        
        % Region1: droping bags
        R_13.R_dropping.r1 = [220 430 1 750]* 2 * scale; %r1;%[103 266 61 436];
        % Region4: Belt
        R_13.R_belt.r4 = [24 216 1 550] * 2 * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
        %R_13.R_belt.r4 = r4;
        R_13.rot_angle = 90;
        %% Region background
        counter = 0;
        im_back = 0;
        
        while hasFrame(v_13) && counter < 10
            im_frame = readFrame(v_13);
            im_back = im_back + double(im_frame);
            counter = counter + 1;
        end
        R_13.im_background = im_back / (counter);
        R_13.im_background = uint8(R_13.im_background);
        
        %load('imback.mat','R_13.im_background');
        R_13.im_background = imresize(R_13.im_background, scale);
        R_13.im_background = imrotate(R_13.im_background, R_13.rot_angle);
        
        
        R_13.im_background = lensdistort(R_13.im_background, k_distort_13); % solve radial distortion
        
        R_13.R_belt.flow = [];
        R_13.R_dropping.flow = [];
        
        R_13.R_belt.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
            'NeighborhoodSize', 20, 'FilterSize', 20);
        R_13.R_dropping.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
            'NeighborhoodSize', 20, 'FilterSize', 20);
        
        
        R_13.R_belt.im_r4_p = R_13.im_background(R_13.R_belt.r4(3):R_13.R_belt.r4(4),R_13.R_belt.r4(1):R_13.R_belt.r4(2),:);
        R_13.R_dropping.im_r1_p = R_13.im_background(R_13.R_dropping.r1(3):R_13.R_dropping.r1(4),R_13.R_dropping.r1(1):R_13.R_dropping.r1(2),:);
        %R_13.R_dropping.im_r1_p = lensdistort(R_13.R_dropping.im_r1_p, k_distort_11);
        
        % object information for each region
        R_13.R_dropping.r1_obj = [];
        %     R_13.R_belt.r4_obj = [];
        % sequence of bin and people
        R_13.people_seq = [];
        R_13.bin_seq = {};
        R_13.bin_array={};
        R_13.people_array = {};
        % object count for each region
        R_13.R_dropping.r1_cnt = 0;
        R_13.R_dropping.r1_lb = 0;
        %R_13.R_belt.r4_cnt = 0;
        % object Labels
        R_13.R_dropping.label = 1;
        R_13.R_belt.label = 1;
        starting_index = -1;
        R_13.R_dropping.prev_body = [];
        
    end
    
    %% Start tracking and baggage association
    R_11.frame_count = start_fr;
    
    while hasFrame(v_11) && v_11.CurrentTime < ( end_f / v_11.FrameRate )
        
        img = readFrame(v_11);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_11.rot_angle);
        
        if R_11.frame_count >= 2625
            1;
        end
        
        im_c = lensdistort(im_c, k_distort_11);
        
        %% tracking the people
        % people tracking variables
        im_r = im_c(R_11.R_dropping.r1(3):(R_11.R_dropping.r1(4)),R_11.R_dropping.r1(1):R_11.R_dropping.r1(2),:);
        R_people_var = [];
        R_people_var.thres_low = 0.4;
        R_people_var.thres_up = 1.5;
        R_people_var.min_allowed_dis = 200 * scale;
        R_people_var.limit_area = 9000 * scale^2;
        R_people_var.limit_small_area = 4000 * scale^2;
        R_people_var.limit_init_area = 14000 *  scale^2;
        R_people_var.limit_max_width = 420 *  scale;
        R_people_var.limit_max_height = 420 * scale;
        R_people_var.half_y = 900 * scale; %1.8 * size(im_r,1) / 2;
        R_people_var.limit_exit_y1 = 1300 * scale;
        R_people_var.limit_exit_x1 = 10 * scale;
        R_people_var.limit_exit_y2 = 1370 * scale;
        R_people_var.limit_exit_x2 = 10 * scale;
        R_people_var.threshold_img = 30 ;
        R_people_var.init_max_x = 127 * 2 * scale;

        R_people_var.thres_critical_del = 6;
        R_people_var.thres_temp_count_low = 15;
        R_people_var.thres_temp_count_high = 100;
        
        R_people_var.critical_exit_x = 0.5 * size(im_r, 2);
        R_people_var.critical_exit_y = 0.4 * size(im_r, 1);
        
        %%
        
        if debug == true && tmp == 0
            R_people_var.half_y =  0.9 * size(im_r, 1); 
            tmp = 1;
            if R_com_info.check_13 ~= 0
                R_people_var.half_y = 900 * scale; 
            end
        else
            R_people_var.half_y = 900 * scale; 
        end
        
        [R_11, R_com_info] = a_peopletracking_camera11_13(im_r, R_11 ,R_people_var, R_com_info, R_c9, 11);
        
        % tracking the bin
        %[R_11.bin_seq, R_11.bin_array, R_11.R_belt] = a_solve_bin_bin_tracking_camera11(im_c,R_11.R_dropping,...
        %    R_11.R_belt,R_11.bin_seq,R_11.bin_array, R_11.people_array, R_c9);
        
        %         figure(3);
        %         imshow(im_c);
        %         drawnow;
        
        title(num2str(R_11.frame_count));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if show_image
            image = displayimage_camera11(im_c, R_11.R_belt, R_11.R_dropping, R_11.bin_array, ...
                R_11.people_array, R_11.bin_seq, R_11.people_seq);
        end
        
        %% check camera 13
        if associate_13 && R_com_info.check_13 ~=0  
            
            if R_com_info.check_13 == 1
                v_13.CurrentTime = v_11.CurrentTime + diff_frame_sec;
                R_com_info.check_13 = 2;
            end
            
            img = readFrame(v_13);
            im_c = imresize(img,scale);%original image
            im_c = imrotate(im_c, R_13.rot_angle);
            im_c = lensdistort(im_c, k_distort_13);
            
            im_r = im_c(R_13.R_dropping.r1(3):(R_13.R_dropping.r1(4)),R_13.R_dropping.r1(1):R_13.R_dropping.r1(2),:);
            R_people_var = [];
            R_people_var.thres_low = 0.4;
            R_people_var.thres_up = 1.5;
            R_people_var.min_allowed_dis = 200 * scale;
            R_people_var.limit_area = 14000 * scale^2;
            R_people_var.limit_init_area = 35000 *  scale^2;
            R_people_var.limit_max_width = 420 *  scale;
            R_people_var.limit_max_height = 420 * scale;
            R_people_var.half_y = 500 * scale; %1.8 * size(im_r,1) / 2;
            R_people_var.limit_exit_y1 = 1300 * scale;
            R_people_var.limit_exit_x1 = 10 * scale;
            R_people_var.limit_exit_y2 = 1300 * scale;
            R_people_var.limit_exit_x2 = 10 * scale;
            R_people_var.threshold_img = 30 ;
            R_people_var.limit_small_area = 4000 * scale^2;

            R_people_var.thres_critical_del = 6;
            R_people_var.thres_temp_count_low = 15;
            R_people_var.thres_temp_count_high = 100;
            
            R_people_var.critical_exit_x = 0.5 * size(im_r, 2);
            R_people_var.critical_exit_y = 0.4 * size(im_r, 1);
            
             R_people_var.init_limit_exit_x1 = 200;
             R_people_var.init_limit_exit_y1 = 40;
            
            %%
            [R_13, R_com_info] = a_peopletracking_camera11_13(im_r, R_13 ,R_people_var, R_com_info, R_c9, 13);
            
            
        end
        
        %warning('off', 'last');
        
        if is_write_video && show_image
            writeVideo(outputVideo,image);
        end
        
        disp(R_11.frame_count);
        
        R_11.frame_count = R_11.frame_count + 1;
        
    end
    
    if is_write_video
        close(outputVideo);
    end
    beep;
    
end


