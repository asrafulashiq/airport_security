
show_image = true;
my_decision = 0;
is_write_video = false;

scale = 1;

start_fr = 600;


%% load video data
% % %for mac sys
% file for input video

all_file_nums = "10A";%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    
    if ~exist(input_filename)
        input_filename = fullfile('..',file_number, 'Camera_9.mp4');
    end
    
    v = VideoReader(input_filename);
    
    %% the file for the outputvideo
    if is_write_video
        output_filename = fullfile('..',file_number, ['_output_' file_number '_new.avi']);
        outputVideo = VideoWriter(output_filename);
        outputVideo.FrameRate = v.FrameRate;
        open(outputVideo);
    end
    
    %% file to save variables
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars.mat']);
    
    %% region setting,find region position
    
    % Region1: droping bags
    R_dropping.r1 = [996 1396 512 2073] * scale; %r1;%[103 266 61 436];
    % Region4: Belt
    R_belt.r4 = [660 990 536 1676] * scale ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    %R_belt.r4 = r4;
    rot_angle = 102;
    %% Region background
    counter = 0;
    im_back = 0.0;
    while hasFrame(v) && counter < 5
        im_frame = readFrame(v);
        im_back = im_back + double(im_frame);
        counter = counter + 1;
    end
    im_background = im_back / (counter);
    im_background = uint8(im_background);
    
    %load('imback.mat','im_background');
    im_background = imresize(im_background, scale);
    im_background = imrotate(im_background, rot_angle);
    
    
    R_belt.im_r4_p = im_background(R_belt.r4(3):R_belt.r4(4),R_belt.r4(1):R_belt.r4(2),:);
    R_dropping.im_r1_p = im_background(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
    
    people_seq = {};
    bin_seq = {};
    bin_array={};
    people_array = {};
    
    starting_index = -1;
    
    %% the parameter for the start frame and end frame
    end_f = v.Duration * v.FrameRate ; %15500;
    v.CurrentTime = start_fr / 30;%v.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        im_c = imrotate(im_c, rot_angle);
        
        if frame_count > 912
            1;
        end
        
%         figure(1);
%         imshow(im_c);
%         drawnow;
        % tracking the people
%         [people_seq, people_array] = a_peopletracking2(im_c,R_dropping,...
%             R_belt,people_seq,people_array, bin_array);
        
        r4 = R_belt.r4;
        im_r = im_c(r4(3):r4(4),r4(1):r4(2),:);

        
        %% Region 1 background subtraction
        
        %im_fore = abs(R_dropping.im_r1_p - im_r) + abs(im_r - R_dropping.im_r1_p);
        %im2_b = im2bw(im_fore,0.18);
        
        im_r_hsv = rgb2hsv(im_r);
        im_p_hsv = rgb2hsv(R_belt.im_r4_p);
        
        im_fore = abs(im_r_hsv(:,:,2)-im_p_hsv(:,:,2)) + abs(im_p_hsv(:,:,2) - im_r_hsv(:,:,2));
        %im_fore(im_fore < 0.2) = 0;
        im_fore = uint8(im_fore*255);
        % filter the image with gaussian filter
        %h = fspecial('gaussian',[5,5],2);
        %im2_b = imfilter(im2_b,h);
        %im2_b2 = im2_b;
        im_filtered = imgaussfilt(im_fore, 6);
        im_filtered(im_filtered < 50) = 0;
        % close operation for the image
        se = strel('disk',10);
        im_closed = imclose(im_filtered,se);
        
        im_binary = logical(im_closed); %extract people region

        cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'ConvexImage'); % extract parameters
        im_draw = im_r;
        body_prop = [];
        for i = 1:size(cpro_r1, 1)
           if cpro_r1(i).Area > 10000
            body_prop = [body_prop; cpro_r1(i)];
            im_draw = insertShape(im_draw, 'Rectangle', int32(cpro_r1(i).BoundingBox), 'LineWidth', 10);
           end
        end
             
        %im_hsv = rgb2hsv(im_r);
        figure(2); imshow(im_draw);drawnow;
        
        
        if is_write_video
            writeVideo(outputVideo,image);
        end
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end


