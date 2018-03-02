
global scale;

%% file names
R_5.filename = fullfile(basename, '5'); % input file
R_5.file_to_save =  fullfile('..',file_number, [file_number '_cam5_vars'  '.mat']); % file to save variables
R_5.write_video_filename = fullfile('..',file_number, ['cam5_output_' file_number '.avi']); % file to save video

%% frame info

x = dir(R_5.filename);
len = numel(x);
lastfilename = split(x(len).name,'.');
R_5.end_frame = str2num(lastfilename{1});


%% people region
R_5.R_people.reg = [];

R_5.R_people.people_seq = {}; % store exit people info
R_5.R_people.people_array = {}; % current people info
R_5.R_people.label = 1; % people label

% set initial people detector properties
R_5.R_people.min_allowed_dis = 200 * scale;
R_5.R_people.limit_area = 8000 * 4 * scale^2;
R_5.R_people.limit_init_area = 9000 * 4 *  scale^2;
R_5.R_people.limit_init_max_area = 60000 * 4 *  scale^2;
R_5.R_people.limit_max_width = 450 *  scale;
R_5.R_people.limit_max_height = 600 * scale;
R_5.R_people.half_y = 390 * 2 * scale;

R_5.R_people.enter_x_cam_11 = 60 * 2 * scale;
R_5.R_people.enter_y_cam_11 = 581 * 2 * scale;

R_5.R_people.exit_x_cam_9 = 100 * 2 * scale;
R_5.R_people.exit_x_cam_9_all = 60 * 2 * scale; % for combined videos
R_5.R_people.exit_y_cam_9 = 581 * 2 * scale;

R_5.R_people.limit_exit_x1 = 240 * scale;
R_5.R_people.limit_exit_y2 = 874 * 2 * scale;
R_5.R_people.limit_exit_x2 = 2 * 2 * scale;

R_5.R_people.limit_init_y = 250 * 2 * scale;
R_5.R_people.limit_init_x = 480 * 2 * scale;

R_5.R_people.limit_exit_y = 1000 * 2 * scale;
R_5.R_people.limit_exit_x = 70 * 2 * scale;

R_5.R_people.threshold_img = 25;


R_5.R_people.limit_flow = 0.04;
R_5.R_people.limit_exit_max_area = 14000 * 4 * scale^2;
R_5.R_people.limit_flow_mag = 0.05;
R_5.R_people.limit_half_x = 210 * scale;
R_5.R_people.limit_max_displacement = 300 * scale;

%% angle of rotation
R_5.rot_angle = 90;


%% background of camera 
R_5.im_background = get_background(R_5.filename, 10);

% get people background
im = R_5.im_background;
im = imresize(im,scale);%original image
im = imrotate(im, R_5.rot_angle);

R_5.R_people.im_back = im;




