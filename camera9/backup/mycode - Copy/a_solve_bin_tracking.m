%% clear all variable
clearvars;
close all;
clc;

%% control variable
is_do_nothing = 0;
is_write_video = false;
is_load_region = 2; % flag to load region data from respective matfile
my_decision = 2;

%% load video data
% % %for mac sys
% file for input video

all_file_nums = "5A_take1";%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile(file_number, ['camera9_' file_number '.mp4']);
    v = VideoReader(input_filename);
    
    my_decision = is_load_region;
    file_to_save = fullfile(file_number, ['camera9_' file_number '_vars.mat']);
    
    load(file_to_save); % start_f will load here    
    
    %% the parameter for the start frame and end frame
    end_f = 3000;%v.Duration * v.FrameRate ; %15500;
    start_fr = 840;
    v.CurrentTime = start_fr / v.FrameRate ;
    
    %% region setting,find region position
    
    load(fullfile('Experi1A','r1.mat'));
    load(fullfile('Experi1A','r4.mat'));
    % load('region_pos2.mat');
    
    % Region1: droping bags
    R_dropping.r1 = r1;%[103 266 61 436];
    % Region4: Belt
    R_belt.r4 = r4+5;%[10 93 90 396];
    
    %% Region background
    
    im_background = imread(fullfile('Experi1A','camera9_1A_back.jpg'));%background image
    R_belt.im_r4_p = im_background(R_belt.r4(3):R_belt.r4(4),R_belt.r4(1):R_belt.r4(2),:);
    R_dropping.im_r1_p = im_background(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
    % object information for each region
    R_dropping.r1_obj = [];
    R_belt.r4_obj = [];
    % sequence of bin and people
    people_seq = [];
    bin_seq = [];
    % object count for each region
    R_dropping.r1_cnt = 0;
    R_belt.r4_cnt = 0;
    % object Labels
    R_dropping.r1_lb = 0;
    R_belt.r4_lb = 0;
    starting_index = -1;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    
    %blob_tracker = vision.PointTracker;
    
    htm=vision.TemplateMatcher;

    T_in = imread('template1.jpg');
    T = rgb2gray(T_in);
    w = size(T,2);
    h = size(T,1)+10;
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        im_c = imresize(readFrame(v),0.25);%original image
        im_c = imrotate(im_c, 100);
        % Region 1
        %im_r1 = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
        % Region 1 background subtraction
        %im_r1 = abs(R_dropping.im_r1_p - im_r1) + abs(im_r1 - R_dropping.im_r1_p);
        %im2_b = im2bw(im_r1,0.18);
        %filter the image with gaussian filter
        %h = fspecial('gaussian',[5,5],2);
        %im2_b = imfilter(im2_b,h);
        %im2_b2 = im2_b;
        %close operation for the image
        %se = strel('disk',10);
        %im2_b = imclose(im2_b,se);
        
        if my_decision == is_load_region
            
            starting_index = start_fr - start_f;
            
            if starting_index > 0
                R_dropping.r1_obj = m_r1_obj{starting_index};
                R_dropping.r1_cnt = m_r1_cnt(starting_index);
                R_dropping.r1_lb = m_r1_lb(starting_index) ;
                
                R_belt.r4_obj = m_r4_obj{starting_index};
                R_belt.r4_cnt = m_r4_cnt(starting_index);
                R_belt.r4_lb = m_r4_lb(starting_index);
            end
            my_decision = is_do_nothing;
            
        end
        
        % tracking the people
        % [R_dropping,people_seq] = a_peopletracking(im2_b,R_dropping,people_seq);
        
        % tracking the bin
        %[R_belt,im_c,bin_seq] = a_bintracking(im2_b,im_c,R_dropping,R_belt,bin_seq);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %image = displayimage(im_c,R_dropping,R_belt,people_seq,bin_seq);
        
        r4 = R_belt.r4; 
        im_r4 = im_c(r4(3):r4(4),r4(1):r4(2),:);
 
        
        
%         if frame_count==start_fr
%             corner_points = detectMinEigenFeatures( rgb2gray(im_r4),'ROI',[14 65 70 56] );
%             initialize(blob_tracker, corner_points.Location, im_r4);
%             
%             figure(1);imshow(im_r4);
%             hold on; plot(corner_points.selectStrongest(37));
%             drawnow;
%             
%         else
%             [corner_points validity] = blob_tracker(im_r4);
%             out = insertMarker(im_r4, corner_points(validity, :),'+');
%             figure(1);imshow(out);
%             drawnow;
%             
%         end
        
        I = rgb2gray(im_r4);
        
        Loc=step(htm,I,T)  ;
            
        x = Loc(1); y = Loc(2);
        
        % calc bounding box
        width_T = size(T_in,2);
        
        height_T = size(T_in,1);
        
        bbox = int64 ([ max(1,x-width_T/2) max(1,y-height_T/2)...
            min( x+width_T/2, size(I,2))  min(y+height_T/2, size(I,1)) ] );
        
        T = I(bbox(2):bbox(4), bbox(1):bbox(3));
        
        im_and_shape = insertShape( I,'Rectangle',[ bbox(1) bbox(2) width_T height_T ]);
        
        figure(1);
        imshow(im_and_shape);
        
        figure(2);imshow(T);
        drawnow;
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    beep;
    
end


