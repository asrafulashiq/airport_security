update_region = 3; % flag to update region data from respective matfile

my_decision = 0;
global k_distort;
global scale;
scale = 0.5;

%% load video data
% file for input video

all_file_nums = [ "6A"];%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, 'camera13.mp4');
    
    if ~exist(input_filename)
        input_filename = fullfile('..',file_number, 'Camera_13.mp4');
        if ~exist(input_filename)
           error('file does not exist'); 
        end
    end
    
    v_13 = VideoReader(input_filename);

    start_fr = 2770;   
    
    %% region setting,find region position   
    
    % Region1: droping bags 
    R_13.R_people.r1 = [220 430 1 750]* 2 * scale; %r1;%[103 266 61 436];
    % Region4: Belt
    R_13.R_bin.r4 = [24 216 1 550] * 2 * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_13.R_bin.r4 = r4;
    R_13.rot_angle = 90;
    %% Region background
    counter = 0;
    im_back = 0;
        
    k_distort = -0.20;

    
    detector = vision.ForegroundDetector(...
       'NumTrainingFrames', 100, ... 
       'InitialVariance', 30*30);
   
   blob = vision.BlobAnalysis(...
       'CentroidOutputPort', false, 'AreaOutputPort', false, ...
       'BoundingBoxOutputPort', true, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 1000);
   
   shapeInserter = vision.ShapeInserter('BorderColor','White');
  
%     while hasFrame(v_13) && counter < 10
%         im_frame = readFrame(v_13);
%         
%         im_c = imresize(im_frame,scale);%original image
%         im_c = imrotate(im_c, R_13.rot_angle);
%         
%         im_c = lensdistort(im_c, k_distort);
% 
%         im_c = im_c(R_13.R_people.r1(3):R_13.R_people.r1(4),R_13.R_people.r1(1):R_13.R_people.r1(2),:);
%         
%         im_back = im_back + double(im_c);
%         counter = counter + 1;
%         
%         %fgMask = step(detector, im_c);
%         
%         disp(counter);
%         
%     end
%     R_13.im_background = im_back / (counter);
%     R_13.im_background = uint8(R_13.im_background);
    
    %load('imback.mat','R_13.im_background');
    %R_13.im_background = imresize(R_13.im_background, scale);
    %R_13.im_background = imrotate(R_13.im_background, R_13.rot_angle);
    

    %R_13.im_background = lensdistort(R_13.im_background, k_distort); % solve radial distortion
    
    R_13.R_bin.flow = [];
    R_13.R_people.flow = [];
    
    R_13.R_bin.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    R_13.R_people.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
    
    
    %R_13.R_bin.im_r4_p = R_13.im_background (R_13.R_bin.r4(3):R_13.R_bin.r4(4),R_13.R_bin.r4(1):R_13.R_bin.r4(2),:);
    %R_13.R_people.im_r1_p = R_13.im_background(R_13.R_people.r1(3):R_13.R_people.r1(4),R_13.R_people.r1(1):R_13.R_people.r1(2),:);
    %R_13.R_people.im_r1_p = lensdistort(R_13.R_people.im_r1_p, k_distort);
    
    % object information for each region
    R_13.R_people.r1_obj = [];
    %     R_13.R_bin.r4_obj = [];
    % sequence of bin and people
    R_13.people_seq = {};
    R_13.bin_seq = {};
    bin_array={};
    people_array = {};
    % object count for each region
    R_13.R_people.r1_cnt = 0;
    R_13.R_people.r1_lb = 0;
    %R_13.R_bin.r4_cnt = 0;
    % object Labels
    R_13.R_people.label = 1;
    R_13.R_bin.label = 1;
    starting_index = -1; 
    R_13.R_people.prev_body = [];
    
    %% the parameter for the start frame and end frame
    end_f = v_13.Duration * v_13.FrameRate ; %15500;
    v_13.CurrentTime = start_fr / 30;%v_13.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
      
    while hasFrame(v_13) && v_13.CurrentTime < ( end_f / v_13.FrameRate )
        
        img = readFrame(v_13);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_13.rot_angle);
        
        if frame_count >= 3573
            1;
        end
        
        im_c = lensdistort(im_c, k_distort);
        
        im_2 = im_c(R_13.R_people.r1(3):R_13.R_people.r1(4),R_13.R_people.r1(1):R_13.R_people.r1(2),:);
        
        flow = estimateFlow(R_13.R_people.optic_flow, rgb2gray(im_2));
        
        
        title(num2str(frame_count));

   
        figure(1);
        imshow(im_2);
        hold on;
        plot(flow,'DecimationFactor',[5 5],'ScaleFactor',2);
        hold off;
        
        
        
        drawnow;
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end

    
    beep;
    
end


    

