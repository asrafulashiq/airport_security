
clear all;
update_region = 3; % flag to update region data from respective matfile

my_decision = 0;
global k_distort;
global scale;
scale = 0.5;

%% load video data
% file for input video

all_file_nums = ["6A","7A", "9A","10A"];
all_cameras = [9,10,11,12,13];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str);
    
    for camera = all_cameras
    
        filename = fullfile('..',file_number, sprintf('camera%d.mp4', camera));
        
        basename = fullfile('..','all_videos',file_number, int2str(camera));
        
        v = VideoReader(filename);
        
        k = 1;
        while hasFrame(v)
            img = readFrame(v);
            
            fwrite = fullfile(basename, sprintf('%04d.jpg', k));
            imwrite(img, fwrite);
            
            k = k + 1;
            
        end
        
    end
    
end


    

