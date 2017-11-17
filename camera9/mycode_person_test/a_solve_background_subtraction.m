%% clear all variable
%clearvars;
%close all;
%clc;

global scale;
scale = 0.5;

show_image = true;
is_write_video = false;

my_decision = 1;

%% load video data
% file for input video

all_file_nums = ["10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    
    v = VideoReader(input_filename);
    
    %% the file for the outputvideo
    if is_write_video
        output_filename = fullfile('..',file_number, ['test_output_' file_number '_comb.avi']);
        outputVideo = VideoWriter(output_filename);
        outputVideo.FrameRate = v.FrameRate;
        open(outputVideo);
    end
    
    %% file to save variables
    
    start_fr = 1119;
    
    %% region setting,find region position
    
    % Region1: droping bags
    R_dropping.r1 = [996 1396 512 2073] * scale; %r1;%[103 266 61 436];
    
    
    
    % camera 10 area
    R_dropping.r_c10 = uint32([1300 1800 377 930] * scale);
    
    % Region4: Belt
    R_belt.r4 = [660 990 536 1676] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    ROI = [665 536 970-665 1676-990] * scale;
    %R_belt.r4 = r4;
    rot_angle = 102;
    %% Region background
    im_back = 0.0;
    
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
    
    opticFlow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10, 'NeighborhoodSize', 20, 'FilterSize', 20);
    
    roi = [1 115 86 180];
    tracker = vision.PointTracker('NumPyramidLevels', 33, 'BlockSize', [7 7], 'MaxBidirectionalError',11);
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        
        r4 = R_belt.r4;
        %r1 = R_dropping.r1;
        im_actual = im_c(r4(3):r4(4),r4(1)+10:r4(2),:);
        %im_actual = im_c;
        
        im_g = rgb2gray(im_actual);
        
        K = stdfilt(im_g, true(5));
        K = mat2gray(K);
        K(K<0.3) = 0;
        Ka = K;
        %K = edge(K, 'sobel');
        
        Kb = logical(K);
        
        crn = detectHarrisFeatures(Kb);

        
        %corners = detectMinEigenFeatures(im_g,'FilterSize', 75);%detectHarrisFeatures(im_g, 'FilterSize', 25);
        %corners = detectFASTFeatures(im_g);
        %flow = estimateFlow(opticFlow, im_g);
        
        %i_med = imgaussfilt(im_g,2);
        
        
        
        flow = estimateFlow(opticFlow, im_g);
        
        %BW2 = bwareaopen(Kb, 100);
        
       
        
%         figure(3);
%         imshow(i_med,[]);
        
        figure(1);
        imshow(im_g);
        
%         im_lab = rgb2hsv(im_actual);
%         
%         figure(2);
%         imshow(im_lab(:,:,2),[]);
        
        
        figure(2); 
        imshow(Ka);
        
        hold on;
        plot(flow,'DecimationFactor',[5 5],'ScaleFactor',5);
        
        hold on;
        plot(crn);
        
        
        
        %hold off;
        drawnow;
        
   
        
        title(num2str(frame_count));
        
        warning('off','last');
        
        disp('-------------');
        disp(frame_count);
        disp('-------------');
        
        frame_count = frame_count + 1;
        
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


