
global scale;

%% file names
R_2.filename = fullfile(basename, '2'); % input file
R_2.file_to_save =  fullfile('..',file_number, [file_number '_cam2_vars'  '.mat']); % file to save variables
R_2.write_video_filename = fullfile('..',file_number, ['cam2_output_' file_number '.avi']); % file to save video

%% frame info

x = dir(R_2.filename);
len = numel(x);
lastfilename = split(x(len).name,'.');
R_2.end_frame = str2num(lastfilename{1});


%% people region
R_2.R_people.reg = [];

R_2.R_people.people_seq = {}; % store exit people info
R_2.R_people.people_array = {}; % current people info
R_2.R_people.label = 1; % people label

% set initial people detector properties
R_2.R_people.min_allowed_dis = 200 * scale;
R_2.R_people.limit_area = 8000 * 4 * scale^2;
R_2.R_people.limit_init_area = 13000 * 4 *  scale^2;
R_2.R_people.limit_init_max_area = 40000 * 4 *  scale^2;
R_2.R_people.limit_max_width = 350 * 2 *  scale;
R_2.R_people.limit_max_height = 350 * 2 * scale;
R_2.R_people.half_y = 390 * 2 * scale;

R_2.R_people.enter_x_cam_9 = 60 * 2 * scale;
R_2.R_people.enter_y_cam_9 = 581 * 2 * scale;

R_2.R_people.exit_x_cam_9 = 80 * 2 * scale;
R_2.R_people.exit_x_cam_9_all = 60 * 2 * scale; % for combined videos
R_2.R_people.exit_y_cam_9 = 581 * 2 * scale;

R_2.R_people.limit_exit_x1 = 240 * scale;

R_2.R_people.limit_exit_y2 = 520 * 2 * scale;
R_2.R_people.limit_exit_x2 = 267 * 2 * scale;

R_2.R_people.limit_init_y = 600 * 2 * scale;
R_2.R_people.limit_init_x = 333 * 2 * scale;

R_2.R_people.limit_exit_y = 800 * 2 * scale;
R_2.R_people.limit_exit_x = 64* 2 * scale;

R_2.R_people.threshold_img = 15;
R_2.R_people.limit_flow = 0.04;
R_2.R_people.limit_exit_max_area = 14000 * 4 * scale^2;
R_2.R_people.limit_flow_mag = 0.05;
R_2.R_people.limit_half_x = 210 * scale;
R_2.R_people.limit_max_displacement = 300 * scale;

%% angle of rotation
R_2.rot_angle = 90;


%% background of camera 
R_2.im_background = get_background(R_2.filename, 10);

% get people background
im = R_2.im_background;
im = imresize(im,scale);%original image
im = imrotate(im, R_2.rot_angle);

R_2.R_people.im_back = im;




