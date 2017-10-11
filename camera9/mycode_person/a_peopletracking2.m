function [people_seq, people_array] = a_peopletracking2(im_c,R_dropping,...
    R_belt,people_seq,people_array, bin_array)
%% background subtraction
im_r1 = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
% Region 1 background subtraction
im_r1 = abs(R_dropping.im_r1_p - im_r1) + abs(im_r1 - R_dropping.im_r1_p);
im2_b = im2bw(im_r1,0.18);
% filter the image with gaussian filter
h = fspecial('gaussian',[5,5],2);
im2_b = imfilter(im2_b,h);
im2_b2 = im2_b;
% close operation for the image
se = strel('disk',10);
im2_b = imclose(im2_b,se);

%% test matlab built-in people tracking




end