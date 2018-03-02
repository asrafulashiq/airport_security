



R_11.R_people.reg = [570 1080-120 300 1800] * scale;

%R_11.R_people.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
%        'NeighborhoodSize', 20, 'FilterSize', 20);

R_11.R_people.people_seq = {}; % store exit people info
R_11.R_people.people_array = {}; % current people info
R_11.R_people.label = 1; % people label

% set initial people detector properties
R_11.R_people.min_allowed_dis = 200 * scale;
R_11.R_people.limit_area = 8000 * 4 * scale^2;
R_11.R_people.limit_area_med = 12000 * 4 *scale^2;
R_11.R_people.limit_init_area = 15000 * 4 *  scale^2;
R_11.R_people.limit_max_width = 450 *  scale;
R_11.R_people.limit_max_height = 600 * scale;
R_11.R_people.half_y = 1000 * scale;
R_11.R_people.limit_exit_x1 = 240 * scale;
R_11.R_people.limit_exit_y2 = 600 * scale;
R_11.R_people.limit_exit_x2 = 220 * scale;
R_11.R_people.limit_init_y = 950 * scale;
R_11.R_people.limit_init_x = 300 * scale;

R_11.R_people.limit_exit_y = 1300 * scale;
R_11.R_people.limit_exit_x = 2 * scale;
R_11.R_people.threshold_img = 15;
R_11.R_people.limit_flow = 1500;
R_11.R_people.limit_exit_max_area = 10000 * 4 * scale^2;
R_11.R_people.limit_flow_mag = 0.05;
R_11.R_people.half_x = 315 * scale;
R_11.R_people.limit_max_displacement = 300 * scale;
%% belt/bin region
R_11.R_bin.reg = [230 550 150-140 1920] * scale ;

R_11.R_bin.label = 1;
R_11.R_bin.bin_seq = {};
R_11.R_bin.bin_array={};
R_11.R_bin.threshold = 15; 
R_11.R_bin.limit_exit_y = 1800 * scale;
R_11.R_bin.limit_distance = 220 * scale;
R_11.R_bin.threshold_img = 15;
R_11.R_bin.limit_area = 16000 * 4 * scale^2;
R_11.R_bin.limit_min_area = 12000 * 4 * scale^2;
R_11.R_bin.limit_area2 = 20000 * 4 * scale^2;
R_11.R_bin.limit_max_area = 40000 * 4 * scale^2;
R_11.R_bin.limit_init_y = 250 * 2 * scale; 
R_11.R_bin.solidness_ratio = 31;
R_11.R_bin.area_ratio = 2;

%%
x = dir(R_11.filename);
len = numel(x);
lastfilename = split(x(len).name,'.');
R_11.end_frame = str2num(lastfilename{1});


%% people region
R_11.R_people.reg = ([996 1396 542 2073] * scale);

R_11.R_people.people_seq = {}; % store exit people info
R_11.R_people.people_array = {}; % current people info
R_11.R_people.label = 1; % people label

% set initial people detector properties
R_11.R_people.min_allowed_dis = 200 * scale;
R_11.R_people.limit_area = 8000 * 4 * scale^2;
R_11.R_people.limit_init_area = 13000 * 4 *  scale^2;
R_11.R_people.limit_init_max_area = 40000 * 4 *  scale^2;
R_11.R_people.limit_max_width = 450 *  scale;
R_11.R_people.limit_max_height = 600 * scale;
R_11.R_people.half_y = 220 * 2 * scale;%0.3 * size(im_r,1) / 2;
R_11.R_people.half_y = 1070 * scale;
R_11.R_people.limit_exit_x1 = 240 * scale;
R_11.R_people.limit_exit_y2 = 600 * scale;
R_11.R_people.limit_exit_x2 = 220 * scale;

R_11.R_people.limit_init_y = 450 * scale;
R_11.R_people.limit_init_x = 200 * scale;

R_11.R_people.limit_exit_y = 515 * 2 * scale;
R_11.R_people.limit_exit_x = 316 * scale;
R_11.R_people.threshold_img = 10;
R_11.R_people.limit_flow = 1500;
R_11.R_people.limit_exit_max_area = 15000 * 4 * scale^2;
R_11.R_people.limit_flow_mag = 0.05;
R_11.R_people.limit_half_x = 210 * scale;
R_11.R_people.limit_max_displacement = 300 * scale;

%% belt/bin region
R_11.R_bin.reg = ([640 990 500 1676] * scale) ;
R_11.R_bin.label = 1;
R_11.R_bin.bin_seq = {};
R_11.R_bin.bin_array={};
R_11.R_bin.threshold = 15; 
R_11.R_bin.limit_exit_y = 1060 * scale;
R_11.R_bin.limit_distance = 220 * scale;
R_11.R_bin.threshold_img = 15;
R_11.R_bin.limit_area = 16000 * 4 * scale^2;
R_11.R_bin.limit_min_area = 12000 * 4 * scale^2;
R_11.R_bin.limit_area2 = 20000 * 4 * scale^2;
R_11.R_bin.limit_max_area = 40000 * 4 * scale^2;
R_11.R_bin.limit_init_y = 270 * 2 * scale; 
R_11.R_bin.solidness_ratio = 31;
R_11.R_bin.area_ratio = 2;
R_11.R_bin.limit_max_dist = 280 * scale;