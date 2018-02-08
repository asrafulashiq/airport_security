R_5.file_save_info = fullfile(basename,'infor_5.mat');
R_5.write = false;
R_5.save_info = false;

% video R_5.write
if R_5.write
    R_5.writer = VideoWriter('../video_main_5.avi');
    open(R_5.writer);
end
% flow path
if ~isempty(base_shared_name)
    R_5.flow_dir = fullfile(base_shared_name,file_number,'5_flow' );
    %R_5.flow_dir_npy = fullfile(base_shared_name,file_number,'9_np' );
end

%% start with camera 9
% set camera 9 constant properties
setProperties5;
R_5.start_frame = 4120;
R_5.current_frame = R_5.start_frame;