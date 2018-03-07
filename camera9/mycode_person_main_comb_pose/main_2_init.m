R_2.file_save_info = fullfile(basename,'infor_2.mat');
R_2.write = true;
R_2.save_info = true;

R_2.R_people.stack_of_people = {};

% video R_2.write
if R_2.write
    R_2.writer = VideoWriter('../video_main_2.avi');
    open(R_2.writer);
end

% flow path
if ~isempty(base_shared_name)
    R_2.flow_dir = fullfile(base_shared_name,file_number,'2_flow' );
end

%% start with camera 9
% set camera 9 constant properties
setProperties2;
R_2.start_frame = 323;
R_2.current_frame = R_2.start_frame;