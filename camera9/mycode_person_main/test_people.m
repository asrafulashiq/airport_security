
show_image = true;
my_decision = 0;
is_write_video = false;

scale = 0.5;

start_fr = 2000;


%% load video data
% % %for mac sys
% file for input video

all_file_nums = "9A";%["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera10.mp4']);
    
    
    v = VideoReader(input_filename);
    
    
    
    %% file to save variables
    file_to_save = fullfile('..',file_number, ['camera9_' file_number '_vars.mat']);
    
    %% region setting,find region position
    
    % Region1: droping bags
    R.r = uint32([1300 1800 377 930] * scale); %r1;%[103 266 61 436];
    
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
    
    im_background = imresize(im_background, scale);
    %im_background = imrotate(im_background, rot_angle);
    
    
    R.im_back = im_background(R.r(3):R.r(4),R.r(1):R.r(2),:);
    
    
    starting_index = -1;
    
    %% the parameter for the start frame and end frame
    end_f = v.Duration * v.FrameRate ; %15500;
    v.CurrentTime = start_fr / 30;%v.FrameRate ;
    
    %% Start tracking and baggage association
    frame_count = start_fr;
    v.CurrentTime = 105;
    
    while hasFrame(v) && v.CurrentTime < ( end_f / v.FrameRate )
        
        img = readFrame(v);
        im_c = imresize(img,scale);%original image
        %im_c = imrotate(im_c, rot_angle);
        
        if frame_count > 912
            1;
        end
        
%         figure(1);
%         imshow(im_c);
%         drawnow;
        % tracking the people
%         [people_seq, people_array] = a_peopletracking2(im_c,R_dropping,...
%             R_belt,people_seq,people_array, bin_array);
        
        im_r = im_c(R.r(3):R.r(4),R.r(1):R.r(2),:);
        
        %% Region 1 background subtraction
        
        threshold = 130;
        im_r_hsv = rgb2hsv(im_r);
        im_p_hsv = rgb2hsv(R.im_back);
        
        im_fore = abs(im_r_hsv(:,:,3)-im_p_hsv(:,:,3)) + abs(im_p_hsv(:,:,3) - im_r_hsv(:,:,3));
        %im_fore(im_fore < 0.2) = 0;
        
        im_fore = uint8(im_fore*255);
        im_fore(im_fore < threshold) = 0;
        im_filtered = imgaussfilt(im_fore, 6);
        im_filtered(im_filtered < 50) = 0;
        se = strel('disk',10);
        im_closed = imclose(im_filtered,se);
        
        im_binary = logical(im_closed); %extract people region

        cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox'); % extract parameters
        im_draw = im_r;
       body_prop = [];
        for i = 1:size(cpro_r1, 1)
           if cpro_r1(i).Area > 5000
            body_prop = [body_prop; cpro_r1(i)];
            im_draw = insertShape(im_draw, 'Rectangle', int32(cpro_r1(i).BoundingBox), 'LineWidth', 10);
           end
        end
             
        %im_hsv = rgb2hsv(im_r);
        figure(2); imshow(im_draw);  
        title(sprintf('%d',frame_count));
        xlabel('x');
        drawnow;
        
       
        
        disp(frame_count);
        
        frame_count = frame_count + 1;
        
    end
    
    if is_write_video
        close(outputVideo);
    end
    
    beep;
    
end
