%% clear all variable
%clearvars;
%close all;
%clc;

%% control variable

is_write_video = true;

is_do_nothing = 0;
is_save_region = 1; % flag to save region data to matfile in a completely new fashion
is_load_region = 2; % flag to load region data from respective matfile
is_update_region = 3; % flag to update region data from respective matfile

my_decision = 0;

%% load video data
% % %for mac sys
% file for input video

all_file_nums = "6A";%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    v = VideoReader(input_filename);
    
    %% the file for the outputvideo
    if is_write_video
        output_filename = fullfile('..',file_number, ['_output_' file_number '.avi']);
        outputVideo = VideoWriter(output_filename);
        outputVideo.FrameRate = v.FrameRate;
        open(outputVideo);
    end
    
    %% file to save variables
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars.mat']);
    
    start_fr = 350;
    
    if my_decision == is_update_region
        load(file_to_save);
        
    elseif my_decision == is_load_region
        load(file_to_save); % start_f will load here
        
    elseif my_decision == is_save_region
        start_f = start_fr; % starting frame for saving
        save(file_to_save, 'start_f'); % creating file_to_save
        m_r1_obj = {};  m_r4_obj = {};
        m_r1_cnt = [];  m_r4_cnt = [];
        m_r1_lb = [];   m_r4_lb = [];
        
    end
    
    %% the parameter for the start frame and end frame
    end_f = v.Duration * v.FrameRate ; %15500;
    % start_f = 1000;
    v.CurrentTime = start_fr / v.FrameRate ;
    
    %% region setting,find region position
    
    load(fullfile('..','Experi1A','r1.mat'));
    load(fullfile('..','Experi1A','r4.mat'));
    % load('region_pos2.mat');
    
    % Region1: droping bags
    R_dropping.r1 = r1;%[103 266 61 436];
    % Region4: Belt
    R_belt.r4 = [161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_belt.r4 = r4;
    
    %% Region background
    
    im_background = imread(fullfile('..','Experi1A','camera9_1A_back.jpg'));%background image
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
    template = [];
    bin_array={};
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        im_c = imresize(readFrame(v),0.25);%original image
        im_c = imrotate(im_c, 100);
        % Region 1
        im_r1 = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
        % Region 1 background subtraction
        im_r1 = abs(R_dropping.im_r1_p - im_r1) + abs(im_r1 - R_dropping.im_r1_p);
        im2_b = im2bw(im_r1,0.18);
        %filter the image with gaussian filter
        h = fspecial('gaussian',[5,5],2);
        im2_b = imfilter(im2_b,h);
        im2_b2 = im2_b;
        %close operation for the image
        se = strel('disk',10);
        im2_b = imclose(im2_b,se);
        
        if my_decision == is_load_region ||  ( my_decision == is_update_region && starting_index == -1 )
            
            starting_index = start_fr - start_f;
            
            if starting_index > 0
                R_dropping.r1_obj = m_r1_obj{starting_index};
                R_dropping.r1_cnt = m_r1_cnt(starting_index);
                R_dropping.r1_lb = m_r1_lb(starting_index) ;
                
                R_belt.r4_obj = m_r4_obj{starting_index};
                R_belt.r4_cnt = m_r4_cnt(starting_index);
                R_belt.r4_lb = m_r4_lb(starting_index);
            end
            
            if my_decision == is_load_region
                my_decision = is_do_nothing;
            end
            
            if my_decision == is_update_region
                
                m_r1_obj = {m_r1_obj{1, 1:starting_index}};
                m_r4_obj = {m_r1_obj{1, 1:starting_index}};
                m_r1_cnt = m_r1_cnt(1:starting_index);
                m_r4_cnt = m_r1_cnt(1:starting_index);
                m_r1_lb = m_r1_cnt(1:starting_index);
                m_r4_lb = m_r1_cnt(1:starting_index);
                
            end
            
        end
        
        if frame_count >= 620
           1; 
        end
        
        % tracking the people
        [R_dropping,people_seq] = a_peopletracking(im2_b,R_dropping,people_seq);
        
        % tracking the bin
        [R_belt,im_c,bin_seq,bin_array] = a_solve_bin_bin_tracking_2(im2_b,im_c,R_dropping,R_belt,bin_seq,bin_array);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        image = displayimage(im_c,R_dropping,R_belt,people_seq,bin_seq);
        
        
        
        %%%%% save variables
        %     eval(['R_dropping_' int2str(frame_count) ' = R_dropping']);
        %     eval(['R_belt_' int2str(frame_count) ' = R_belt']);
        %
        %     save(file_to_save,['R_belt_' int2str(frame_count)],'-append');
        %     save(file_to_save,['R_dropping_' int2str(frame_count)],'-append');
        
        
        if my_decision == is_save_region || my_decision == is_update_region
            
            m_r1_obj{end+1} =  R_dropping.r1_obj ;
            m_r1_cnt(end+1) =  R_dropping.r1_cnt;
            m_r1_lb(end+1)  =  R_dropping.r1_lb;
            
            m_r4_obj{end+1} =  R_belt.r4_obj ;
            m_r4_cnt(end+1) =  R_belt.r4_cnt;
            m_r4_lb(end+1)  =  R_belt.r4_lb;
            
        end
        
        if is_write_video
            writeVideo(outputVideo,image);        
        end
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    if my_decision == is_save_region || my_decision == is_update_region
        if my_decision == is_save_region
            start_f = start_fr;
        end
        
        save(file_to_save, 'm_r1_obj', 'm_r1_cnt', 'm_r1_lb', 'm_r4_obj', 'm_r4_cnt', ...
            'm_r4_lb', 'start_f');
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


