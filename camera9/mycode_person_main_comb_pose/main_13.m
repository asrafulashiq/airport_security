
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

setup_paths(); 


%% load video data
all_file_nums = ["9A"];
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
    R_13.writer = VideoWriter('../video_main_13.avi');
    open(R_13.writer);
    
    % flow path
    if ~isempty(base_shared_name)
       R_13.flow_dir = fullfile(base_shared_name,file_number,sprintf('13_flow'));
       %R_13.flow_dir_npy = fullfile(base_shared_name,file_number,'11_np' );
    end
    
    %% start with camera 9  
    % set camera 9 constant properties
    setProperties13;
    R_13.start_frame = 1540;
    R_13.current_frame = R_13.start_frame;
    
    % 
    load('..\all_videos\9A\infor_11.mat');
    R_13.R_bin.stack_of_bins = R_11.R_bin.bin_seq;
    
    
    %% read video
    while R_13.current_frame <= R_13.end_frame
        
        img = imread(fullfile(R_13.filename, sprintf('%04i.jpg', R_13.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_13.rot_angle);
        
        % flow image
        try 
            im_flow_all = imread(fullfile(R_13.flow_dir, sprintf('%04d_flow.jpg', R_13.current_frame)));
            im_flow_all = imrotate(im_flow_all, R_13.rot_angle);
        catch
            warning('Error reading file : %s',...
                fullfile(R_13.flow_dir, sprintf('%04d_flow.jpg', R_13.current_frame)));
            im_flow_all = [];
        end
        
        if R_13.current_frame  >= 1984
            1;
        end
        %% bin tracking
        
        % initial bin detection
        
        %% bin tracking
        im_b = im_c(R_13.R_bin.reg(3):R_13.R_bin.reg(4),R_13.R_bin.reg(1):R_13.R_bin.reg(2),:); % people region
        
        
        
        %% people tracking
        im_r = im_c(R_13.R_people.reg(3):R_13.R_people.reg(4),R_13.R_people.reg(1):R_13.R_people.reg(2),:); % people region
        
%         if ~isempty(im_flow_all)
%            im_flow = im_flow_all(R_13.R_people.reg(3):R_13.R_people.reg(4),R_13.R_people.reg(1):R_13.R_people.reg(2),:);
%         else
%             im_flow = [];
%         end
%         
%         % detect people
%         R_13.R_people = people_detector_tracking_13(im_r, im_flow, R_13.R_people);
        
        %% display image
        display_image_bin(im_b, R_13);
%         display_image_people(im_r, R_13);
               
        %% increment frame
        R_13.current_frame = R_13.current_frame + 1;
        fprintf('frame : %04i\n', R_13.current_frame);
        
        %warning('off','last');
        writeVideo(R_13.writer, im);

    end
    
    close(R_13.writer);
    
end
