
all_file_nums = ["7A","9A"];
%all_file_nums = ["EXP_1A"];

for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = 'E:\shared_folder\all_videos\7A\9_flow';
    
    
    start_fr = 2800;
    
    
    % Region1: droping bags
    r1 = [996 1396 512 2073] * 0.5; %r1;%[103 266 61 436];
    
    
    % Region4: Belt
    R_belt.r4 = [660 990 536 1676] * 0.5 ; %[161   243   123   386]; %r4+5;%[10 93 90 396];
    
    %R_belt.r4 = r4;
    rot_angle = 102;
    
    startF = 370;
    curF = startF;
    endF = 5000;
    
    people = {};
    
    while curF < endF
        
        im = imread(fullfile(input_filename, sprintf('%04d_flow.jpg', curF)));
        
        im_c = imrotate(im, rot_angle);
        im_actual = im_c(r1(3):r1(4),r1(1):r1(2),:);
        
        img = rgb2gray(im_actual);
        
        thres = 10;
        
        im_filtered = imgaussfilt(img, 6);
        im_filtered(im_filtered < thres) = 0;
        % close operation for the image
        se = strel('disk',15);
        im_closed = imclose(im_filtered,se);
        %im_eroded = imerode(im_closed, se);
        im_binary = logical(im_closed); %extract people region
        im_binary = imfill(im_binary, 'holes');
      
        limit_area = 10000;
        
        cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox'); % extract parameters
        body_prop = cpro_r1([cpro_r1.Area] > limit_area);
        
        insert_ind = [];
       
        for i = 1:numel(body_prop)
            k = 1;
            for j = 1:numel(people)
               if norm(people{j}.Centroid - body_prop(i).Centroid) < 150 && ...
                       body_prop(i).Area > 0.5 * people{j}.Area && ...
                       body_prop(i).Area < 2 * people{j}.Area
                   people{j} = body_prop(i);
                   k = 0;
                   break;
               end
            end
            
            if k==1
                insert_ind(end+1) = i;
            end
        end
        
        for l = insert_ind
           people{end+1} = body_prop(l);
        end
        
        for i=1:numel(people)
           
            im_actual = insertShape(im_actual, 'Rectangle', people{i}.BoundingBox, 'LineWidth', 8);
             
        end
        
        figure(1);
        subplot(1,2,1);
        imshow(im_actual);
        subplot(1,2,2);
        imshow(im_binary);
        drawnow;
        
        pause(0.25);
   
        disp(curF);
        curF = curF + 1;
        
        
    end
    
    
    
    beep;
    
end


