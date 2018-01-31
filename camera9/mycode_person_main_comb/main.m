
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
    
    % flow path
    if ~isempty(base_shared_name)
       R_9.flow_dir = fullfile(base_shared_name,file_number,'9_flow' );
       R_9.flow_dir_npy = fullfile(base_shared_name,file_number,'9_np' );
    end
    
    %% start with camera 9  
    % set camera 9 constant properties
    setProperties9;
    R_9.start_frame = 4540;
    R_9.current_frame = R_9.start_frame;
    
    %% read video
    while R_9.current_frame <= R_9.end_frame
        
        img = imread(fullfile(R_9.filename, sprintf('%04i.jpg', R_9.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_9.rot_angle);
        
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
        
        % initial bin detection
        
        %% bin tracking
%         im_b = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % people region
%         
%         % initial bin detection
%         R_9.R_bin = bin_detector(im_b, R_9);
%         
%         % tracking
%         bin_array = R_9.R_bin.bin_array;
%         
%         del_exit = [];
%         for i = 1:numel(bin_array)
%            if isempty(bin_array{i}.tracker)
%                % init tracker
%                tracker = BACF_tracker(im_b, bin_array{i}.BoundingBox);           
%            else
%               tracker = bin_array{i}.tracker; 
%            end
%            [bin_array{i}.tracker, bb] = tracker.runTrack(im_b);
%            bin_array{i}.BoundingBox = bb;
%            bin_array{i}.Centroid = [bb(1)+bb(3)/2 bb(2)+bb(4)/2]';
%            
%            % detect exit
%            
%            if bin_array{i}.Centroid(2) > R_9.R_bin.dis_exit_y 
%                 R_9.R_bin.bin_seq{end+1} = bin_array{i};
%                 del_exit(end+1) = i;
%            end
%            
%            
%        
%         end
%         bin_array(del_exit) = [];
%         R_9.R_bin.bin_array = bin_array;
        
        %% people tracking
        im_r = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region
        
        if ~isempty(im_flow_all)
           im_flow = im_flow_all(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:);
        else
            im_flow = [];
        end
        
        % detect people
        R_9.R_people = people_detector_tracking(im_r, im_flow, R_9.R_people);
        
        
        %% display image
        %display_image_bin(im_b, R_9);
        display_image_people(im_r, R_9);
               
        %% increment frame
        R_9.current_frame = R_9.current_frame + 1;
        fprintf('frame : %04i\n', R_9.current_frame);
        
        %warning('off','last');
        
    end
    
end
