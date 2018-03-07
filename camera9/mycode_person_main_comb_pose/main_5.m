
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

R_5.write = true;
R_5.save_info = true;

setup_paths(); 


%% load video data
all_file_nums = ["9A"];
base_folder_name = fullfile('E:\shared_folder\all_videos');

% shared folder name
base_shared_name = [];
if ispc
    base_shared_name = fullfile('E:','shared_folder','all_videos');
end
    
for file_number_str = all_file_nums

    file_number = char(file_number_str);
    basename = fullfile(base_folder_name, file_number);
    R_5.file_save_info = fullfile(basename,'infor_5.mat');
    
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
    R_5.start_frame = 1230;
    R_5.current_frame = R_5.start_frame;
    R_5.end_frame = 2130;
    %% read video
    while R_5.current_frame <= R_5.end_frame
        
        img = imread(fullfile(R_5.filename, sprintf('%04i.jpg', R_5.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_5.rot_angle);
        
        if R_5.current_frame >= 1934
           1; 
        end
        
        % flow image
        try 
            im_flow_all = imread(fullfile(R_5.flow_dir, sprintf('%04d_flow.jpg', R_5.current_frame)));
            im_flow_all = imrotate(im_flow_all, R_5.rot_angle);
        catch
            warning('Error reading file : %s',...
                fullfile(R_5.flow_dir, sprintf('%04d_flow.jpg', R_5.current_frame)));
            im_flow_all = [];
        end
        
        if R_5.current_frame  >= 1984
            1;
        end

     
        
        %% people tracking
        im_r = im_c;%(R_5.R_people.reg(3):R_5.R_people.reg(4),R_5.R_people.reg(1):R_5.R_people.reg(2),:); % people region
        
        if ~isempty(im_flow_all)
           im_flow_people = im_flow_all;%(R_5.R_people.reg(3):R_5.R_people.reg(4),R_5.R_people.reg(1):R_5.R_people.reg(2),:);
        else
            im_flow_people = [];
        end
        
        % detect people
        R_5.R_people = people_detector_tracking_5(im_r, im_flow_people, R_5.R_people);
        
        %% display image
        %display_image_bin(im_b, R_5);
        %im = display_image_people(im_r, R_5);
        
        im = display_image_2(im_c, R_5, 5);
               
        %% increment frame
        R_5.current_frame = R_5.current_frame + 1;
        fprintf('frame : %04i\n', R_5.current_frame);
        
        %warning('off','last');
        
        % R_5.write
        if R_5.write
            writeVideo(R_5.writer, im);
        end
        
    end
    
    
    
    if R_5.write
        close(R_5.writer);
    end
    
    if R_5.save_info
       save(R_5.file_save_info, 'R_5');
    end
    
end
