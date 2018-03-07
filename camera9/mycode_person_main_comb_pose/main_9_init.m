global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

R_9.write = true;
R_9.save_info = true;

setup_paths();
addpath('BBS_util');

%% load video data
base_folder_name = fullfile('E:\shared_folder\all_videos');

% shared folder name
base_shared_name = [];
if ispc
    base_shared_name = fullfile('E:','shared_folder','all_videos');
end


basename = fullfile(base_folder_name, file_number);
R_9.file_save_info = fullfile(basename,'infor_9.mat');

% video R_9.write
if R_9.write
    R_9.writer = VideoWriter('../video_main_9.avi');
    open(R_9.writer);
end
% flow path
if ~isempty(base_shared_name)
    R_9.flow_dir = fullfile(base_shared_name,file_number,'9_flow' );
end

%% start with camera 9
% set camera 9 constant properties
setProperties9;
R_9.start_frame = start_frame;
R_9.current_frame = R_9.start_frame;
