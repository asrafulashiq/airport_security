%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable

global scale;
scale = 0.5;


%% some test

%f_test = fopen('f_test.txt', 'at');

%%
show_image = true;
is_write_video = true;
is_do_nothing = 0;
is_save_region = 1; % flag to save region data to matfile in a completely new fashion
is_load_region = 2; % flag to load region data from respective matfile
is_update_region = 3; % flag to update region data from respective matfile

my_decision = 0;
global k_distort;
k_distort = -0.24;

%% load video data
% file for input video

all_file_nums = ["6A"];%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, 'camera11.mp4');
    
    
    
    v = VideoReader(input_filename);
    
    start_fr = 2760;

    
    %% region setting,find region position
   
    
    % Region1: droping bags 
    R_dropping.r1 = [570 1080 286 1800] * scale; %r1;%[103 266 61 436];
    % Region4: Belt
    R_belt.r4 = [230 550 150-140 1920] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_belt.r4 = r4;
    rot_angle = 90;
    %% Region background
    counter = 0;
    im_back = 0;
    
    
    
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
    
    opticFlow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10, 'NeighborhoodSize', 20, 'FilterSize', 20);

    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        im_c = lensdistort(im_c, k_distort);

        %r4 = R_belt.r4;
        r1 = R_dropping.r1;
        %im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);
        im_actual = im_c(r1(3):r1(4),r1(1):r1(2),:);
        %im_actual = im_c;
        
        im_g = rgb2gray(im_actual);
       
        %corners = detectHarrisFeatures(im_g,'ROI', ROI);
              
        
        flow = estimateFlow(opticFlow, im_g);
        
        figure(1);
        imshow(im_actual);
        hold on;

        plot(flow,'DecimationFactor',[5 5],'ScaleFactor',10);
        
        %plot(corners);
        
   
        
        %Kb = logical(K);
        %Kt = edge(Kb, 'sobel');
        
%         figure(2);
%         imshow(Kb);
        hold off;

        drawnow;
        
        title(num2str(frame_count));
        
   
        warning('off', 'last');
     

        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end

    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


