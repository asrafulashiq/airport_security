
global scale;

%% file names
R_9.filename = fullfile(basename, '9'); % input file
R_9.file_to_save =  fullfile('..',file_number, [file_number '_cam9_vars'  '.mat']); % file to save variables
R_9.write_video_filename = fullfile('..',file_number, ['cam9_output_' file_number '.avi']); % file to save video

%% frame info

x = dir(R_9.filename);
len = numel(x);
lastfilename = split(x(len).name,'.');
R_9.end_frame = str2num(lastfilename{1});

R_9.max_flow_thres = 90000;

%% people region

R_9.R_people.stack_of_people = {};
R_9.R_people.reg = ([996 1396 542 2073] * scale); % x,y = 498, 271

R_9.R_people.people_seq = {}; % store exit people info
R_9.R_people.people_array = {}; % current people info
R_9.R_people.label = 1; % people label

% set initial people detector properties
R_9.R_people.min_allowed_dis = 200 * scale;
R_9.R_people.limit_area = 8000 * 4 * scale^2;
R_9.R_people.limit_init_area = 13000 * 4 *  scale^2;
R_9.R_people.limit_init_max_area = 40000 * 4 *  scale^2;
R_9.R_people.limit_max_width = 450 *  scale;
R_9.R_people.limit_max_height = 600 * scale;
R_9.R_people.half_y = 220 * 2 * scale;%0.3 * size(im_r,1) / 2;
R_9.R_people.half_y = 1070 * scale;
R_9.R_people.limit_exit_x1 = 240 * scale;
R_9.R_people.limit_exit_y2 = 600 * scale;
R_9.R_people.limit_exit_x2 = 220 * scale;

R_9.R_people.limit_init_y = 450 * scale;
R_9.R_people.limit_init_x = 200 * scale;

R_9.R_people.limit_exit_y = 515 * 2 * scale;
R_9.R_people.limit_exit_x = 316 * scale;
R_9.R_people.threshold_img = 10;
R_9.R_people.limit_flow = 1500;
R_9.R_people.limit_exit_max_area = 15000 * 4 * scale^2;
R_9.R_people.limit_flow_mag = 0.05;
R_9.R_people.limit_half_x = 210 * scale;
R_9.R_people.limit_max_displacement = 300 * scale;

%% belt/bin region
R_9.R_bin.reg = ([640 990 500 1676] * scale) ;
R_9.R_bin.label = 1;
R_9.R_bin.bin_seq = {};
R_9.R_bin.bin_array={};
R_9.R_bin.threshold = 15; 
R_9.R_bin.limit_exit_y = 1060 * scale;
R_9.R_bin.limit_distance = 220 * scale;
R_9.R_bin.threshold_img = 15;
R_9.R_bin.limit_area = 16000 * 4 * scale^2;
R_9.R_bin.limit_min_area = 12000 * 4 * scale^2;
R_9.R_bin.limit_area2 = 20000 * 4 * scale^2;
R_9.R_bin.limit_max_area = 40000 * 4 * scale^2;
R_9.R_bin.limit_init_y = 270 * 2 * scale; 
R_9.R_bin.solidness_ratio = 31;
R_9.R_bin.area_ratio = 2;
R_9.R_bin.limit_max_dist = 280 * scale;
%% angle of rotation
R_9.rot_angle = 102;


%% background of camera 
R_9.im_background = get_background(R_9.filename, 10);

% get people background
im = R_9.im_background;
im = imresize(im,scale);%original image
im = imrotate(im, R_9.rot_angle);

R_9.R_people.im_back = im(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:);
R_9.R_bin.im_back = im(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:);




