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

global save_features;
save_features = false;
is_save_for_test = 0;

global associate_10;
associate_10 = true;

show_image = true;
is_write_video = true;
is_save_region = 1; % flag to save region data to matfile in a completely new fashion


my_decision = 1;

%% load video data
% file for input video

all_file_nums = ["6A"];
%all_file_nums = ["EXP_1A"];

R_bin.imno = 1;
R_bin.filenames = {};
R_bin.bb = {};

R_people.imno = 1;
R_people.imageFilenames = {};
R_people.BoundingBox = {};
R_people.person_id = {};

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
    
    
    start_fr = 330;
    
    %% region setting,find region position
    
    %% some test on foreground
    %     R_bin.fore_detector = vision.ForegroundDetector(...
    %        'NumTrainingFrames', 5, ...
    %        'InitialVariance', 30*30);
    %
    %     R_bin.blob = vision.BlobAnalysis(...
    %        'CentroidOutputPort', false, 'AreaOutputPort', false, ...
    %        'BoundingBoxOutputPort', true, ...
    %        'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 250, 'MaximumBlobArea', 3000);
    %    R_bin.shapeInserter = vision.ShapeInserter('BorderColor','Black','LineWidth', 3);
    %
    %%
    
    % Region1: droping bags
    R_people.r1 = [996 1396 512 2073] * scale; %r1;%[103 266 61 436];
    
    % camera 10 area
    R_people.r_c10 = uint32([1300 1800 377 930] * scale);
    
    % Region4: Belt
    R_bin.r4 = [660 990 536 1676] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_bin.r4 = r4;
    rot_angle = 102;
    %% Region background
    counter = 0;
    im_back = 0.0;
    
    R_bin.flow = [];
    R_people.flow = [];
    
    R_bin.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    R_people.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    
    % read camera 10 background
    file_c10 = fullfile('..',file_number, 'camera10.mp4');
    v10 = VideoReader(file_c10);
    im_back_10 = 0;
    while hasFrame(v10) && counter < 5
        im_frame = readFrame(v10);
        im_back_10 = im_back_10 + double(im_frame);
        counter = counter + 1;
    end
    im_background_c10 = im_back_10 / (counter);
    im_background_c10 = uint8(im_background_c10);
    im_background_c10 = imresize(im_background_c10, scale);
    
    counter = 0;
    % background reading
    %v.CurrentTime = 560/30;
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
    
    R_bin.im_r4_p = im_background(R_bin.r4(3):R_bin.r4(4),R_bin.r4(1):R_bin.r4(2),:);
    R_people.im_r1_p = im_background(R_people.r1(3):R_people.r1(4),R_people.r1(1):R_people.r1(2),:);
    % object information for each region
    R_people.r1_obj = [];
    R_people.im_back_c10 = im_background_c10;
    R_people.exit_from_9 = {};
    R_people.v10 = v10;
    %     R_bin.r4_obj = [];
    % sequence of bin and people
    R_people.people_seq = {};
    R_bin.bin_seq = {};
    R_bin.bin_array={};
    R_people.people_array = {};
    % object count for each region
    R_people.r1_cnt = 0;
    R_people.r1_lb = 0;
    %R_bin.r4_cnt = 0;
    % object Labels
    R_people.label = 1;
    R_bin.label = 1;
    starting_index = -1;
    
    
    %% save images for training
    R_bin.file_number = file_number_str;
    R_bin.imname = 'data';
    R_people.file_number = file_number_str;
    R_people.imname = 'data_people';
    R_people.prev_body = [];
    
    
    %% the parameter for the start frame and end frame
    end_f =  5000; %v.Duration * v.FrameRate ; %15500;
    v.CurrentTime = start_fr / 30;%v.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        
        if frame_count >= 1620
            1;
        end
        
        % tracking the people
        [R_people] = a_peopletracking2(im_c,R_people,...
            R_bin, v.CurrentTime);
        
        % tracking the bin
        [R_bin] = a_solve_bin_bin_tracking_2(im_c,R_people,...
           R_bin);
        
        title(num2str(frame_count));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if show_image
            %image = displayimage2(im_c,R_people,R_bin,R_people.people_seq,R_bin.bin_seq);
            image = displayimage2(im_c, R_bin, R_people, R_bin.bin_array, ...
                R_people.people_array, R_bin.bin_seq, R_people.people_seq);
        end
        
        
        warning('off','last');
        
        if is_write_video && show_image
            writeVideo(outputVideo,image);
        end
        disp('-------------');
        disp(frame_count);
        disp('-------------');
        
        frame_count = frame_count + 1;
        
        
    end
    
    if is_save_for_test
        %save(file_to_save, 'R_people', 'R_bin', 'R_people.people_seq', 'R_bin.bin_seq', 'start_fr', 'frame_count');
        imageFilenames = R_people.imageFilenames;
        BoundingBox = R_people.BoundingBox;
        ids = R_people.person_id;
        fname = sprintf('trainingdata_people_sep_%s.mat', file_number_str);
        %save(fname,'imageFilenames','BoundingBox');
        save(fname,'imageFilenames','BoundingBox', 'ids' );
    end
    
    
    if is_save_region       
       save(file_to_save, 'R_people', 'R_bin', 'start_fr', 'frame_count');
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end

if is_save_for_test
    %save(file_to_save, 'R_people', 'R_bin', 'R_people.people_seq', 'R_bin.bin_seq', 'start_fr', 'frame_count');
    imageFilenames = R_people.imageFilenames;
    BoundingBox = R_people.BoundingBox;
    save('trainingdata_people.mat','imageFilenames','BoundingBox');
end


