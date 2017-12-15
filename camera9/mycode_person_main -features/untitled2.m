
all_file_nums = ["6A", "7A", "9A", "10A"];
%all_file_nums = ["EXP_1A"];
r4 = [660 990 536 1676] * .5;

ash = 1;
scale = 0.5;
rot_angle = 102;


for file_number_str = all_file_nums
    
    file_number = char(file_number_str); % convert to character array
    input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
    
    if ~exist(input_filename)
        input_filename = fullfile('..',file_number, 'camera9.mp4');
    end
    v = VideoReader(input_filename);
    
    counter = 0;
    while hasFrame(v) && counter < 200
        im_frame = readFrame(v);
        
        im_background = im_frame;
        im_background = imresize(im_background, scale);
        im_background = imrotate(im_background, rot_angle);
        
        im_back_belt = im_background(r4(3):r4(4),r4(1):r4(2),:);
        im_back_belt = rgb2gray(im_back_belt);
        
        h = size(im_back_belt, 1);
        b_h = 110;
        
        num_d = round(h / b_h);
        
        for i = 1:num_d
            
            im = im_back_belt( (b_h*(i-1)+1) : (b_h*i), : );
            imwrite(im, fullfile('background', sprintf('%d.jpg', ash)));
            ash = ash + 1;
            disp(ash);
            
        end
        
        
        counter = counter + 1;
    end
    
    
end