clearvars;
close all;
clc;
%% load video data
%filename = 'out.avi';
% % %for mac sys 
filename='out_mac.mp4';
v = VideoReader(filename);
%the file for the outputvideo
outputVideo = VideoWriter('output_0814.avi');
outputVideo.FrameRate = v.FrameRate;
open(outputVideo)
%the parameter for the start frame and end frame
end_f = 15500;
start_f = 3500;
template = rgb2gray(imread('template1.jpg'));
%% region setting,find region position
load('region_pos2.mat');
%Region1: droping bags
R1.r1 = [103 266 61 436];
%Region4: Belt
R4.r4 = [10 93 90 396];
%% Region background
im_p = imread('out_back.jpg');%background image
R4.im_r4_p = im_p(R4.r4(3):R4.r4(4),R4.r4(1):R4.r4(2),:);
R1.im_r1_p = im_p(R1.r1(3):R1.r1(4),R1.r1(1):R1.r1(2),:);
%object information for each region
R1.r1_obj = [];
R4.r4_obj = [];
%sequence of bin and people
people_seq = [];
bin_seq = [];
%object count for each region
R1.r1_cnt = 0;
R4.r4_cnt = 0;
%Object Labels
R1.r1_lb = 0;
R4.r4_lb = 0;
%% Start tracking and baggage association
speed = 1;
for n_im = start_f:speed:end_f
    
    im_c = imresize(read(v,n_im),0.25);%original image
    im_c = imrotate(im_c, -90);
    % Region 1
    im_r1 = im_c(R1.r1(3):R1.r1(4),R1.r1(1):R1.r1(2),:);
    % Region 1 background subtraction
    im_r1 = abs(R1.im_r1_p - im_r1) + abs(im_r1 - R1.im_r1_p);
    im2_b = im2bw(im_r1,0.18);
    %filter the image with gaussian filter
    h = fspecial('gaussian',[5,5],2);
    im2_b = imfilter(im2_b,h);
    im2_b2 = im2_b;
    %close operation for the image
    se = strel('disk',10);
    im2_b = imclose(im2_b,se);
    
    n_im
    % tracking the people
    [R1,people_seq] = peopletracking(im2_b,R1,people_seq);
    % tracking the bin
    [R4,im_c,bin_seq] = bintracking(im2_b,im_c,R1,R4,region_pos2,bin_seq);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    image=displayimage(im_c,R1,R4,people_seq,bin_seq);
    
    %save image to video
    
    writeVideo(outputVideo,image);
    
end
close(outputVideo);


