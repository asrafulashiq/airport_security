R_11.file_save_info = fullfile(basename,'infor_11.mat');
R_11.write = true;
R_11.save_info = true;

R_11.R_people.stack_of_people = {};

% video R_2.write
if R_11.write
%     R_11.writer1 = VideoWriter('../video_main_11_1.avi');
%     R_11.writer2 = VideoWriter('../video_main_11_2.avi');
    R_11.writer = VideoWriter('../video_main_11.avi');
%     open(R_11.writer1);
%     open(R_11.writer2);
    open(R_11.writer)
end

% flow path
if ~isempty(base_shared_name)
    R_11.flow_dir = fullfile(base_shared_name,file_number,'11_flow' );
    %R_11.flow_dir_npy = fullfile(base_shared_name,file_number,'11_np' );
end

%% start with camera 11
% set camera 11 constant properties
setProperties11;
R_11.current_frame = R_11.start_frame;

load('E:\shared_folder\all_videos\9A\infor_9.mat');
R_11.R_bin.stack_of_bins = R_9.R_bin.bin_seq;

global debug_people;
debug_people = false ;

global debug_bin;
debug_bin = false;
