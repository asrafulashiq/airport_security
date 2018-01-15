
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
    
    
    %% read video
    while R_9.current_frame <= R_9.end_frame
        
        img = imread(fullfile(R_9.filename, sprintf('%04i.jpg', R_9.current_frame)));
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        
        
    
    end
    
end
