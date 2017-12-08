%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable
global debug;
global debug_people;
debug = false;
debug_people = false;
global scale;
scale = 0.5;
global associate;
associate = true;
global associate_13;
associate_13 = true;

%% some test

%f_test = fopen('f_test.txt', 'at');

%%
show_image = true;
is_write_video = false;

my_decision = 0;
global k_distort;
k_distort = -0.24;

%% load video data
% file for input video

all_file_nums = [ "6A"];%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

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
    
    if associate_13
        v_13 = VideoReader(input_filename);
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
    
    %%%%%% R_c9
    
    start_fr = 1600;

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
    
    R_11.im_background = lensdistort(R_11.im_background, k_distort); % solve radial distortion
    
    R_11.R_belt.flow = [];
    R_11.R_dropping.flow = [];
    
    R_11.R_belt.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    R_11.R_dropping.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    
    
    R_11.R_belt.im_r4_p = R_11.im_background(R_11.R_belt.r4(3):R_11.R_belt.r4(4),R_11.R_belt.r4(1):R_11.R_belt.r4(2),:);
    R_11.R_dropping.im_r1_p = R_11.im_background(R_11.R_dropping.r1(3):R_11.R_dropping.r1(4),R_11.R_dropping.r1(1):R_11.R_dropping.r1(2),:);
    %R_11.R_dropping.im_r1_p = lensdistort(R_11.R_dropping.im_r1_p, k_distort);
    
    % object information for each region
    R_11.R_dropping.r1_obj = [];
    %     R_11.R_belt.r4_obj = [];
    % sequence of bin and people
    R_11.people_seq = {};
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
        
        k_distort = -0.20;
        
        R_13.im_background = lensdistort(R_13.im_background, k_distort); % solve radial distortion
        
        R_13.R_belt.flow = [];
        R_13.R_dropping.flow = [];
        
        R_13.R_belt.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
            'NeighborhoodSize', 20, 'FilterSize', 20);
        R_13.R_dropping.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
            'NeighborhoodSize', 20, 'FilterSize', 20);
        
        
        R_13.R_belt.im_r4_p = R_13.im_background(R_13.R_belt.r4(3):R_13.R_belt.r4(4),R_13.R_belt.r4(1):R_13.R_belt.r4(2),:);
        R_13.R_dropping.im_r1_p = R_13.im_background(R_13.R_dropping.r1(3):R_13.R_dropping.r1(4),R_13.R_dropping.r1(1):R_13.R_dropping.r1(2),:);
        %R_13.R_dropping.im_r1_p = lensdistort(R_13.R_dropping.im_r1_p, k_distort);
        
        % object information for each region
        R_13.R_dropping.r1_obj = [];
        %     R_13.R_belt.r4_obj = [];
        % sequence of bin and people
        R_13.people_seq = {};
        R_13.bin_seq = {};
        bin_array={};
        people_array = {};
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
    frame_count = start_fr;
    
    while hasFrame(v_11) && v_11.CurrentTime < ( end_f / v_11.FrameRate )
        
        img = readFrame(v_11);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_11.rot_angle);
        
        if frame_count >= 3573
            1;
        end
        
        im_c = lensdistort(im_c, k_distort);
        
        %         if R_11.R_dropping.label == 7
        %             R_11.R_dropping.label = 8;
        %         end
        % tracking the people
        [R_11.people_seq, R_11.people_array, R_11.R_dropping] = a_peopletracking_camera11(im_c,R_11.R_dropping,...
            R_11.R_belt,R_11.people_seq,R_11.people_array, R_11.bin_array, R_c9);
        
        % tracking the bin
        %[R_11.bin_seq, R_11.bin_array, R_11.R_belt] = a_solve_bin_bin_tracking_camera11(im_c,R_11.R_dropping,...
        %    R_11.R_belt,R_11.bin_seq,R_11.bin_array, R_11.people_array, R_c9);
        
        %         figure(3);
        %         imshow(im_c);
        %         drawnow;
        
        title(num2str(frame_count));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if show_image
            image = displayimage_camera11(im_c, R_11.R_belt, R_11.R_dropping, R_11.bin_array, ...
                R_11.people_array, R_11.bin_seq, R_11.people_seq);
        end
        
        
        %warning('off', 'last');
        
        if is_write_video && show_image
            writeVideo(outputVideo,image);
        end
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


