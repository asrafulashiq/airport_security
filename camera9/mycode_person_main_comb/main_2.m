
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;

write = false;
save_info = false;

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
    file_save_info = fullfile(basename,'infor_2.mat');
    
    % video write
    if write
        writer = VideoWriter('../video_main_2.avi');
        open(writer);
    end
    
    % flow path
    if ~isempty(base_shared_name)
       R_2.flow_dir = fullfile(base_shared_name,file_number,'2_flow' );
    end
    
    %% start with camera 9  
    % set camera 9 constant properties
    setProperties2;
    R_2.start_frame = 2030;
    R_2.current_frame = R_2.start_frame;
    
    %% read video
    while R_2.current_frame <= R_2.end_frame
        
        img = imread(fullfile(R_2.filename, sprintf('%04i.jpg', R_2.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_2.rot_angle);
        
        if R_2.current_frame >= 1934
           1; 
        end
        
        % flow image
        try 
            im_flow_all = imread(fullfile(R_2.flow_dir, sprintf('%04d_flow.jpg', R_2.current_frame)));
            im_flow_all = imrotate(im_flow_all, R_2.rot_angle);
        catch
            warning('Error reading file : %s',...
                fullfile(R_2.flow_dir, sprintf('%04d_flow.jpg', R_2.current_frame)));
            im_flow_all = [];
        end
        
        if R_2.current_frame  >= 1984
            1;
        end

        %% people tracking
        im_r = im_c; % people region
        
        if ~isempty(im_flow_all)
           im_flow_people = im_flow_all;
        else
            im_flow_people = [];
        end
        
        % detect people
        R_2.R_people = people_detector_tracking_2(im_r, im_flow_people, R_2.R_people);
        
        
        %% display image
        %display_image_bin(im_b, R_2);
        %im = display_image_people(im_r, R_2);
        
        im = display_image_2(im_c, R_2);
               
        %% increment frame
        R_2.current_frame = R_2.current_frame + 1;
        fprintf('frame : %04i\n', R_2.current_frame);
        
        %warning('off','last');
        
        % write
        if write
            writeVideo(writer, im);
        end
        
    end
    if write
        close(writer);
    end
    
    if save_info
       save(file_save_info, 'R_2');
    end
    
end
