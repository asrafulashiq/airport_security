
%   This script runs the original implementation of Background Aware Correlation Filters (BACF) for visual tracking.
%   the code is tested for Mac, Windows and Linux- you may need to compile
%   some of the mex files.
%   Paper is published in ICCV 2017- Italy
%   Some functions are borrowed from other papers (SRDCF, CCOT, KCF, etc)- and
%   their copyright belongs to the paper's authors.
%   copyright- Hamed Kiani (CMU, RI, 2017)

%   contact me: hamedkg@gmail.com

clear; clc; close all;
%   Load video information
setup_paths();
base_path  = '../../all_videos/7A/11';
seq.scale= 0.5;
seq.k_distort_11 = -0.24;
seq.rot_angle = 90;
seq.r4 = [230 550 150-140 1920] * seq.scale ;
%seq.r4 = [660 990 536 1676] * seq.scale ;

video_path = base_path ;
seq.startF = 1325;

% get initial rect
img = imread(fullfile(base_path, sprintf('%04i.jpg', seq.startF)));
im = imresize(img,seq.scale);%original image
im = imrotate(im, seq.rot_angle);
if seq.k_distort_11~=0
    im = lensdistort(im, seq.k_distort_11);
end
r4 = seq.r4;
im_r = im(r4(3):r4(4),r4(1):r4(2),:);
imshow(im_r);
rect = getrect;

seq.init_rect = round(rect);
%[seq, ground_truth] = load_video_info(video_path);
seq.st_frame = 1;

%gt_boxes = [ground_truth(:,1:2), ground_truth(:,1:2) + ground_truth(:,3:4) - ones(size(ground_truth,1), 2)];

%   Run BACF- main function
learning_rate = 0.013;  %   you can use different learning rate for different benchmarks.
results       = run_BACF(seq, video_path, learning_rate);

