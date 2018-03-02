
setProperties9;
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
    R_9.start_frame = 719;
    R_9.current_frame = R_9.start_frame;
    R_bin = R_9.R_bin;
    %% read video
    new_reg = [310   650   200   890]; % 510
    
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
%         im_b = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % people region
        
        im_b = im_c(new_reg(3):new_reg(4), new_reg(1):new_reg(2),:);
        
        if ~isempty(im_flow_all)
%            im_flow_bin = im_flow_all(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:);
            im_flow_bin = im_flow_all(new_reg(3):new_reg(4), new_reg(1):new_reg(2),:);
        else
            im_flow_bin = [];
        end
        im_flow = im_flow_bin;
        
        im_flow_g = rgb2gray(im_flow);
        im_flow_hsv = rgb2hsv(im_flow);
        
        im_filtered = im_flow_g;%imgaussfilt(im_flow_g, 3);
        im_tmp = im_filtered;
        im_filtered(im_filtered < 20) = 0;
        
        % close operation for the image
        se = strel('disk',5);
        im_closed = im_filtered;%imclose(im_filtered,se);
        im_binary = logical(im_closed); %extract people region
        %im_binary = imfill(im_binary, 'holes');
        im_binary_orig = im_binary;
        
        figure(2);imshow(im_binary);
        figure(3); imshow(im_flow);
        drawnow
        %% initial bin detection
        
        
        
        %% blob analysis
        cpro_r1 = regionprops(im_binary,'all'); % extract parameters
        body_prop = cpro_r1([cpro_r1.Area] > R_bin.limit_area & ...
            [cpro_r1.Area] < R_bin.limit_max_area & [cpro_r1.MinorAxisLength] > 120 & ...
            [cpro_r1.MajorAxisLength]./[cpro_r1.MinorAxisLength] > 1.1 & ...
            [cpro_r1.MajorAxisLength]./[cpro_r1.MinorAxisLength] < 1.8);
        
        
        
        
        %% increment frame
        R_9.current_frame = R_9.current_frame + 1;
        fprintf('frame : %04i\n', R_9.current_frame);
        
        %warning('off','last');
        
        
        
    end
    
    
end
