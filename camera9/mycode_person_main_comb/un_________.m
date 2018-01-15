%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable
global debug;
debug = false;
global scale;
scale = 1;
global debug_people;
debug_people = false;

show_image = false;
is_write_video = false;
is_do_nothing = 0;
is_save_region = 1; % flag to save region data to matfile in a completely new fashion
is_load_region = 2; % flag to load region data from respective matfile
is_update_region = 3; % flag to update region data f   rom respective matfile

my_decision = 1;

%% load video data
% file for input video

all_file_nums = ["6A","7A","9A"];
%all_file_nums = ["EXP_1A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    
    if ~exist(input_filename)
        input_filename = fullfile('..',file_number, 'camera9.mp4');
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
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars2.mat']);


    start_fr = 2800;
    
 
    % Region1: droping bags
    R_dropping.r1 = [996 1396 512 2073] * scale; %r1;%[103 266 61 436];
    
    % camera 10 area
    R_dropping.r_c10 = uint32([1300 1800 377 930] * scale);
    
    % Region4: Belt
    R_belt.r4 = [660 990 536 1676] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_belt.r4 = r4;
    rot_angle = 102;
    %% Region background
    counter = 0;
    im_back = 0.0;
    
    R_belt.flow = [];
    R_dropping.flow = [];

    R_dropping.r1_obj = [];
%    R_dropping.im_back_c10 = im_background_c10;
    R_dropping.exit_from_9 = {};
%    R_dropping.v10 = v10;
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
    
    
    %% save images for training
    
    
    
    R_belt.file_number = file_number_str;
    R_belt.imname = 'data';

    
    
    
    R_dropping.prev_body = [];
    
    %% the parameter for the start frame and end frame
    end_f =  5000; %v.Duration * v.FrameRate ; %15500;
    v.CurrentTime = start_fr / 30;%v.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    load('detector.mat');
    r4 = R_belt.r4;

    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        if mod(frame_count,5)~=0
           frame_count = frame_count + 1;
           continue; 
        end
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);

        if frame_count >= 1620
            1;
        end
        
        [bbox, score, label] = detect(detector, im_actual);
        
        ind = find(score > 0.85);
        %score_m = score(score > 0.85);
        
        
        for i = ind
           im_actual = insertShape(im_actual, 'Rectangle', bbox(i,:), 'LineWidth', 5); 
        end
        
        figure(1);
        imshow(im_actual);
        
        % tracking the people
        %[people_seq, people_array, R_dropping] = a_peopletracking2(im_c,R_dropping,...
        %    R_belt,people_seq,people_array, bin_array, v.CurrentTime);
        
        % tracking the bin
        %[bin_seq, bin_array, R_belt] = a_solve_bin_bin_tracking_2(im_c,R_dropping,...
        %   R_belt,bin_seq,bin_array, people_array);
        
        title(num2str(frame_count));
        
    
        
        
        warning('off','last');

        disp('-------------');
        disp(frame_count);
        disp('-------------');

        frame_count = frame_count + 1;
        
        
    end
    

    
    beep;
    
end


