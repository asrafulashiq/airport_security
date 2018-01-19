
%% control variable
global debug;
debug = false;
global scale;
scale = 0.5;
global debug_people;
debug_people = false;


%% load video data
all_file_nums = ["7A"];
base_folder_name = fullfile('..', 'all_videos');

for file_number_str = all_file_nums

    file_number = char(file_number_str);
    basename = fullfile(base_folder_name, '6A');
    
    %% start with camera 9  
    % set camera 9 constant properties
    setProperties9;
    R_9.start_frame = 1700;
    R_9.current_frame = R_9.start_frame;
    
    %% read video
    while R_9.current_frame <= R_9.end_frame
        
        img = imread(fullfile(R_9.filename, sprintf('%04i.jpg', R_9.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, R_9.rot_angle);
        
        %% bin tracking
        
        % initial bin detection
        
        %% bin tracking
        im_b = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % people region
        
        % initial bin detection
        bin_detector
        
        %% people tracking
        im_r = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region

        % initial people detection
        [R_9.R_people] = people_detector(im_r, R_9.R_people);
        
        %% people tracking
        for i = 1:numel(R_9.R_people.people_array)
            if isempty(R_9.R_people.people_array{i}.tracker)
                % initialize tracker
                tracker = ECO_Tracker();
                tracker = tracker.initTracker(im_r, R_9.R_people.people_array{i}.BoundingBox);
                [tracker, bb] = tracker.runTrack(im_r);
                R_9.R_people.people_array{i}.tracker = tracker;
            else
                [R_9.R_people.people_array{i}.tracker, bb] = ...
                    R_9.R_people.people_array{i}.tracker.runTrack(im_r);
                disp(bb);
                
                R_9.R_people.people_array{i}.BoundingBox = bb;
                R_9.R_people.people_array{i}.Centroid = [bb(1)+(bb(3)-bb(1)+1)/2 bb(2)+(bb(4)-bb(2)+1)/2]';
            end 
            
            % detect exit
            people = R_9.R_people.people_array{i};
            if people.Centroid(1) > R_9.R_people.limit_exit_x1 && ...
                    people.Centroid(2) > R_9.R_people.limit_exit_y1           
                R_9.R_people.people_array{i} = [];
                R_9.R_people.people_seq{end+1} = people;
            end
            
        end
        
        %% display image
        display_image(im_c, R_9);
               
        %% increment frame
        R_9.current_frame = R_9.current_frame + 1;
        fprintf('frame : %04i\n', R_9.current_frame);
        
        warning('off','last');
        
    end
    
end
