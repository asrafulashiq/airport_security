R_13.file_save_info = fullfile(basename,'infor_13.mat');

R_13.write = true;
R_13.save_info = true;

R_13.R_people.stack_of_people = {};

% video R_13.write
if R_13.write
    R_13.writer = VideoWriter('../video_main_13.avi');
    open(R_13.writer);
end


% flow path
if ~isempty(base_shared_name)
    R_13.flow_dir = fullfile(base_shared_name,file_number,sprintf('13_flow'));
    %R_13.flow_dir_npy = fullfile(base_shared_name,file_number,'11_np' );
end

%% start with camera 9
% set camera 9 constant properties
setProperties13;
R_13.start_frame = 3530;
R_13.current_frame = R_13.start_frame;