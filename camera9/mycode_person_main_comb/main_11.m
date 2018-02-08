
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

setup_paths();


%% load video data
all_file_nums = ["7A"];
base_folder_name = fullfile('..', 'all_videos');

% shared folder name
base_shared_name = [];
if ispc
    base_shared_name = fullfile('E:','shared_folder','all_videos');
end

for file_number_str = all_file_nums
    
    file_number = char(file_number_str);
    basename = fullfile(base_folder_name, file_number);
    
     % video write
    R_11.writer = VideoWriter('../video_main_11.avi');
    open(R_11.writer);
    
    % flow path
    if ~isempty(base_shared_name)
        R_11.flow_dir = fullfile(base_shared_name,file_number,'11_flow' );
        %R_11.flow_dir_npy = fullfile(base_shared_name,file_number,'11_np' );
    end
    
    %% start with camera 11
    % set camera 11 constant properties
    setProperties11;
    R_11.start_frame = 2174;
    R_11.current_frame = R_11.start_frame;
    
    %% read video
    while R_11.current_frame <= R_11.end_frame
        
        img = imread(fullfile(R_11.filename, sprintf('%04i.jpg', R_11.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_11.rot_angle);
        
        %im_c = lensdistort(im_c, R_11.R_bin.k_distort);
        % load 9
        load('..\all_videos\7A\infor_9.mat');
        R_11.R_bin.prev_bin = R_9.R_bin.bin_seq;
        
        
        % flow image
        try
            im_flow_all = imread(fullfile(R_11.flow_dir, sprintf('%04d_flow.jpg', R_11.current_frame)));
            im_flow_all = imrotate(im_flow_all, R_11.rot_angle);
        catch
            warning('Error reading file : %s',...
                fullfile(R_11.flow_dir, sprintf('%04d_flow.jpg', R_11.current_frame)));
            im_flow_all = [];
        end
        
        if R_11.current_frame  >= 1984
            1;
        end
        
        %% bin tracking
         im_bins = im_c(R_11.R_bin.reg(3):R_11.R_bin.reg(4),R_11.R_bin.reg(1):R_11.R_bin.reg(2),:); % people region
%         
         im_b = lensdistort(im_bins, R_11.R_bin.k_distort);
%         
%         if ~isempty(im_flow_all)
%             im_flow_bin = im_flow_all(R_11.R_bin.reg(3):R_11.R_bin.reg(4),R_11.R_bin.reg(1):R_11.R_bin.reg(2),:);
%         else
%             im_flow_bin = [];
%         end
%         
%        R_11.R_bin = bin_detection_tracking_11(im_b, im_flow_bin, R_11.R_bin);
        
        %% people tracking
        im_r = im_c(R_11.R_people.reg(3):R_11.R_people.reg(4),R_11.R_people.reg(1):R_11.R_people.reg(2),:); % people region
        
        if ~isempty(im_flow_all)
            im_flow_people = im_flow_all(R_11.R_people.reg(3):R_11.R_people.reg(4),R_11.R_people.reg(1):R_11.R_people.reg(2),:);
        else
            im_flow_people = [];
        end
        
        % detect people
        R_11.R_people = people_detector_tracking_11(im_r, im_flow_people, R_11.R_people);
        
        
        %% display image
%         display_image_bin(im_b, R_11);
        display_image_people(im_r, R_11);
        %display_image(im_c, R_11);
        
        %% increment frame
        R_11.current_frame = R_11.current_frame + 1;
        fprintf('frame : %04i\n', R_11.current_frame);
        
        %warning('off','last');
        
        writeVideo(R_11.writer, im);

        
    end
    
    close(R_11.writer);
    
end
