
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

R_9.write = false;
R_9.save_info = false;

setup_paths(); 


%% load video data
all_file_nums = ["7A"];
base_folder_name = fullfile('E:\shared_folder\all_videos');

% shared folder name
base_shared_name = [];
if ispc
    base_shared_name = fullfile('E:','shared_folder','all_videos');
end
    
for file_number_str = all_file_nums

    file_number = char(file_number_str);
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
       %R_9.flow_dir_npy = fullfile(base_shared_name,file_number,'9_np' );
    end
    
    %% start with camera 9  
    % set camera 9 constant properties
    setProperties9;
    R_9.start_frame = 323;
    R_9.current_frame = R_9.start_frame;
    
    %% read video
    while R_9.current_frame <= R_9.end_frame
        
        img = imread(fullfile(R_9.filename, sprintf('%04i.jpg', R_9.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_9.rot_angle);
        
        if R_9.current_frame >= 1934
           1; 
        end
        
        % flow image
        try 
            im_flow_all = imread(fullfile(R_9.flow_dir, sprintf('%04d_flow.jpg', R_9.current_frame)));
            im_flow_all = imrotate(im_flow_all, R_9.rot_angle);
        catch
            warning('Error reading file : %s',...
                fullfile(R_9.flow_dir, sprintf('%04d_flow.jpg', R_9.current_frame)));
            im_flow_all = [];
        end
        
        if R_9.current_frame  >= 1984
            1;
        end

        %% bin tracking
        im_b = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % people region
        
        if ~isempty(im_flow_all)
           im_flow_bin = im_flow_all(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:);
        else
            im_flow_bin = [];
        end
        
       % R_9.R_bin = bin_detection_tracking(im_b, im_flow_bin, R_9.R_bin);
        R_9.R_bin = bin_detect_prev(im_b, im_flow_bin, R_9.R_bin, R_9.R_people);
       
        
        %% people tracking
        im_r = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region
        
        if ~isempty(im_flow_all)
           im_flow_people = im_flow_all(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:);
        else
            im_flow_people = [];
        end
        
        % detect people
        R_9.R_people = people_detector_tracking(im_r, im_flow_people, R_9.R_people);
        
        
        %% display image
        %display_image_bin(im_b, R_9);
        %im = display_image_people(im_r, R_9);
        
        im = display_image(im_c, R_9);
               
        %% increment frame
        R_9.current_frame = R_9.current_frame + 1;
        fprintf('frame : %04i\n', R_9.current_frame);
        
        %warning('off','last');
        
        % R_9.write
        if R_9.write
            writeVideo(R_9.writer, im);
        end
        
    end
    if R_9.write
        close(R_9.writer);
    end
    
    if R_9.save_info
       save(R_9.file_save_info, 'R_9');
    end
    
end
