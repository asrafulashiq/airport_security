
global scale;

%% file names
R_13.filename = fullfile(basename, '13'); % input file
R_13.file_to_save =  fullfile('..',file_number, [file_number '_cam11_vars'  '.mat']); % file to save variables
R_13.write_video_filename = fullfile('..',file_number, ['cam11_output_' file_number '.avi']); % file to save video

%% frame info

x = dir(R_13.filename);
len = numel(x);
lastfilename = split(x(len).name,'.');
R_13.end_frame = str2num(lastfilename{1});


%% people region
R_13.R_people.reg = [220 430 1 900]* 2 * scale;

R_13.R_people.people_seq = {}; % store exit people info
R_13.R_people.people_array = {}; % current people info
R_13.R_people.label = 1; % people label

% set initial people detector properties
R_13.R_people.min_allowed_dis = 200 * scale;
R_13.R_people.limit_area = 8000 * 4 * scale^2;
R_13.R_people.limit_area_med = 12000 * 4 *scale^2;
R_13.R_people.limit_init_area = 12000 * 4 *  scale^2;
R_13.R_people.limit_max_width = 450 *  scale;
R_13.R_people.limit_max_height = 600 * scale;
R_13.R_people.half_y = 750 * scale;
R_13.R_people.half_x = 300 * scale;

R_13.R_people.limit_exit_x1 = 240 * scale;
R_13.R_people.limit_exit_y2 = 600 * scale;
R_13.R_people.limit_exit_x2 = 220 * scale;
R_13.R_people.limit_init_y = 300 * scale;
R_13.R_people.limit_init_x = 340 * scale;

R_13.R_people.limit_exit_y = 800 * 2 * scale;
R_13.R_people.limit_exit_x = 2 * scale;

R_13.R_people.threshold_img = 20;

R_13.R_people.limit_flow = 1500;
R_13.R_people.limit_exit_max_area = 10000 * 4 * scale^2;
R_13.R_people.limit_flow_mag = 0.05;
R_13.R_people.limit_max_displacement = 300 * scale;

R_13.R_people.max_overlap = 0.3;

%% belt/bin region
R_13.R_bin.reg = [24 216 1 550] * 2 * scale ;

%R_13.R_bin.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
%        'NeighborhoodSize', 20, 'FilterSize', 20);
R_13.R_bin.label = 1;
R_13.R_bin.bin_seq = {};
R_13.R_bin.bin_array={};
R_13.R_bin.threshold = 15; 
R_13.R_bin.dis_exit_y = 1000 * scale;
R_13.R_bin.limit_distance = 220 * scale;
R_13.R_bin.threshold_img = 15;
R_13.R_bin.limit_exit_y = 310 * 2 * scale;

%% angle of rotation
R_13.rot_angle = 90;


%% background of camera 
R_13.im_background = get_background(R_13.filename, 10);

% get people background
im = R_13.im_background;
im = imresize(im,scale);%original image
im = imrotate(im, R_13.rot_angle);

R_13.R_people.im_back = im(R_13.R_people.reg(3):R_13.R_people.reg(4),R_13.R_people.reg(1):R_13.R_people.reg(2),:);
R_13.R_bin.im_back = im(R_13.R_bin.reg(3):R_13.R_bin.reg(4),R_13.R_bin.reg(1):R_13.R_bin.reg(2),:);




