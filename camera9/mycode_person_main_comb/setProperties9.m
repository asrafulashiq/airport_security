%% file names
R_9.filename = fullfile(basename, '9'); % input file
R_9.file_to_save =  fullfile('..',file_number, [file_number '_cam9_vars'  '.mat']); % file to save variables
R_9.write_video_filename = fullfile('..',file_number, ['cam9_output_' file_number '.avi']); % file to save video

%% frame info
R_9.start_frame = 300;
R_9.end_frame = 5000;
R_9.current_frame = R_9.start_frame;

%% people region
R_9.R_people.reg = [996 1396 512 2073] * scale;

R_9.R_people.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);

R_9.R_people.people_seq = {}; % store exit people info
R_9.R_people.people_array = {}; % current people info
R_9.R_people.label = 1; % people label


%% belt/bin region
R_9.R_bin.reg = [660 990 536 1676] * scale ;

R_9.R_bin.optic_flow = opticalFlowFarneback('NumPyramidLevels', 5, 'NumIterations', 10,...
        'NeighborhoodSize', 20, 'FilterSize', 20);
R_9.R_bin.label = 1;
R_9.R_bin.bin_seq = {};
R_9.R_bin.bin_array={};

%% angle of rotation
R_9.rot_angle = 102;


%% background of camera 
R_9.im_background = get_background(R_9.filename, 10);



