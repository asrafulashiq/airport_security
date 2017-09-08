%% clear all variable
clearvars;
close all;
clc;
%% load video data
% % %for mac sys 
% file for input video
file_number = '10A';
input_filename=sprintf('./%s/camera9_%s.mp4', file_number, file_number); 
v = VideoReader(input_filename); 

% the file for the outputvideo
output_filename = sprintf('./%s/_output_%s.avi', file_number, file_number);
outputVideo = VideoWriter(output_filename);
outputVideo.FrameRate = v.FrameRate;
open(outputVideo);

% the parameter for the start frame and end frame
end_f =  v.NumberofFrame; %15500;  
start_f = 50; 

%% region setting,find region position

load('./Experi1A/r1.mat');
load('./Experi1A/r4.mat');
%load('region_pos2.mat');

% Region1: droping bags
R_dropping.r1 = r1;%[103 266 61 436];
% Region4: Belt
R_belt.r4 = r4+5;%[10 93 90 396];

%% Region background

im_background = imread('./Experi1A/camera9_1A_back.jpg');%background image
R_belt.im_r4_p = im_background(R_belt.r4(3):R_belt.r4(4),R_belt.r4(1):R_belt.r4(2),:);
R_dropping.im_r1_p = im_background(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
%object information for each region
R_dropping.r1_obj = [];
R_belt.r4_obj = [];
%sequence of bin and people
people_seq = [];
bin_seq = [];
%object count for each region
R_dropping.r1_cnt = 0;
R_belt.r4_cnt = 0;
%Object Labels
R_dropping.r1_lb = 0;
R_belt.r4_lb = 0;

%% Start tracking and baggage association

speed = 1;
for n_im = start_f:speed:end_f
    
    im_c = imresize(read(v,n_im),0.25);%original image
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
    
    disp(n_im);
    % tracking the people
    [R_dropping,people_seq] = a_peopletracking(im2_b,R_dropping,people_seq);
    % tracking the bin
    [R_belt,im_c,bin_seq] = a_bintracking(im2_b,im_c,R_dropping,R_belt,bin_seq);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    image=displayimage(im_c,R_dropping,R_belt,people_seq,bin_seq);
    
    %save image to video
    
    writeVideo(outputVideo,image);
    
end
close(outputVideo);