%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

show_image = true;
is_write_video = true;
is_do_nothing = 0;
is_save_region = 1; % flag to save region data to matfile in a completely new fashion
is_load_region = 2; % flag to load region data from respective matfile
is_update_region = 3; % flag to update region data from respective matfile

my_decision = 1;

%% load video data
% file for input video

all_file_nums = "9A";%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    
    if ~exist(input_filename)
        input_filename = fullfile('..',file_number, 'Camera_9.mp4');
    end
    
    v = VideoReader(input_filename);
    
    %% the file for the outputvideo
    if is_write_video
        output_filename = fullfile('..',file_number, ['_output_' file_number '_comb.avi']);
        outputVideo = VideoWriter(output_filename);
        outputVideo.FrameRate = v.FrameRate;
        open(outputVideo);
    end
    
    %% file to save variables
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars.mat']);
    
    start_fr = 2610;
    
    if my_decision == is_update_region
        load(file_to_save);
        
    elseif my_decision == is_load_region
        load(file_to_save); % start_f will load here
        
    elseif my_decision == is_save_region
        start_f = start_fr; % starting frame for saving
        save(file_to_save, 'start_f'); % creating file_to_save
        
    end
    
    %% region setting,find region position
    
    load(fullfile('..','Experi1A','r1.mat'));
    load(fullfile('..','Experi1A','r4.mat'));
    % load('region_pos2.mat');
    
    % Region1: droping bags
    R_dropping.r1 = [996 1396 512 2073] * scale; %r1;%[103 266 61 436];
    % Region4: Belt
    R_belt.r4 = [660 990 536 1676] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_belt.r4 = r4;
    rot_angle = 102;
    %% Region background
    counter = 0;
    im_back = 0.0;
    while hasFrame(v) && counter < 10
        im_frame = readFrame(v);
        im_back = im_back + double(im_frame);
        counter = counter + 1;
    end
    im_background = im_back / (counter);
    im_background = uint8(im_background);
    
    %load('imback.mat','im_background');
    im_background = imresize(im_background, scale);
    im_background = imrotate(im_background, rot_angle);
    
    
    R_belt.im_r4_p = im_background(R_belt.r4(3):R_belt.r4(4),R_belt.r4(1):R_belt.r4(2),:);
    R_dropping.im_r1_p = im_background(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
    % object information for each region
    R_dropping.r1_obj = [];
    %     R_belt.r4_obj = [];
    % sequence of bin and people
    people_seq = {};
    bin_seq = {};
    bin_array={};
    people_array = {};
    % object count for each region
    R_dropping.r1_cnt = 0;
    R_dropping.r1_lb = 0;
    %R_belt.r4_cnt = 0;
    % object Labels
    R_dropping.label = 1;
    R_belt.label = 1;
    starting_index = -1;
    
    R_dropping.prev_body = [];
    
    %% the parameter for the start frame and end frame
    end_f = v.Duration * v.FrameRate ; %15500;
    v.CurrentTime = start_fr / 30;%v.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        
        if frame_count >= 2638
            1;
        end
        
        % tracking the people
        [people_seq, people_array, R_dropping] = a_peopletracking2(im_c,R_dropping,...
            R_belt,people_seq,people_array, bin_array);
        
        % tracking the bin
        %[bin_seq, bin_array, R_belt] = a_solve_bin_bin_tracking_2(im_c,R_dropping,...
        %   R_belt,bin_seq,bin_array, people_array);
        
        title(num2str(frame_count));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if show_image
            %image = displayimage2(im_c,R_dropping,R_belt,people_seq,bin_seq);
            image = displayimage2(im_c, R_belt, R_dropping, bin_array, ...
                people_array, bin_seq, people_seq);
        end
        
        
        warning('off','last');

        
        if is_write_video && show_image
            writeVideo(outputVideo,image);
        end
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    if my_decision == is_save_region || my_decision == is_update_region
        if my_decision == is_save_region
            start_f = start_fr;
        end
        
        save(file_to_save, 'R_dropping', 'R_belt', 'people_seq', 'bin_seq', 'start_fr', 'frame_count');
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


