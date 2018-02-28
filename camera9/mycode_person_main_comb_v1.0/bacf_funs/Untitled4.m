
clear; clc; close all;
%   Load video information
setup_paths();
base_path  = '../../all_videos/7A/9';
seq.scale= 0.5;
seq.k_distort_11 = 0;%-0.24;
seq.rot_angle = 102;%90;
%seq.r4 = [230 550 150-140 1920] * seq.scale ;
seq.r4 = [660 990 536 1676] * seq.scale ;

video_path = base_path ;
seq.startF = 2300;

% get initial rect
img = imread(fullfile(base_path, sprintf('%04i.jpg', seq.startF)));
im = imresize(img,seq.scale);%original image
im = imrotate(im, seq.rot_angle);
if seq.k_distort_11~=0
    im = lensdistort(im, seq.k_distort_11);
end
r4 = seq.r4;
im_r = im(r4(3):r4(4),r4(1):r4(2),:);
%imshow(im_r);
%rect = [3 31 161 106];%getrect;

imshow(im_r);
rect = getrect;

pseq.im = im_r;
pseq.init_rect = rect;

tracker = BACF_tracker(im, rect);



%[tracker, rect] = tracker.runTrack(im_r);

i = seq.startF;

while true
    img = imread(fullfile(base_path, sprintf('%04i.jpg', i)));
    im = imresize(img,seq.scale);%original image
    im = imrotate(im, seq.rot_angle);
    if seq.k_distort_11~=0
        im = lensdistort(im, seq.k_distort_11);
    end
    r4 = seq.r4;
    im_r = im(r4(3):r4(4),r4(1):r4(2),:);
    
    [tracker, rect] = tracker.runTrack(im_r);
    rect
    
    disp(i);
    i = i + 1;
    
end







