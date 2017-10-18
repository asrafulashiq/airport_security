file_number = '9A';
input_filename = fullfile('..',file_number, ['camera9_' file_number '.mp4']);
camera_num = '9';

v = VideoReader(input_filename);
frames = 330;

for frame = frames
    im_frame = read(v, frame);
    im_mod = zeros(size(im_frame));
    labeled_file_name = get_CLASP_file_name(file_number, camera_num, frame);
    % get person data from labeled file
    found = false;
    f = fopen(labeled_file_name, 'r');
    while ~feof(f)
        line = fgetl(f);
        line_split = strsplit(line);
        if size(line_split, 2) >= 1 && strcmp(line_split{1}, 'person')
            found = true;
            bbox = str2double([line_split(2) line_split(3) line_split(4) line_split(5)]);
            rot_angle = -str2double(line_split(end));
            
            % extract image
            x_all = bbox(1) : bbox(1)+bbox(3)-1;
            y_all = bbox(2) : bbox(2)+bbox(4)-1;
            [t1, t2] = meshgrid(x_all, y_all);
            xy_all = [t1(:)'; t2(:)'];
            % rotate
            R = [cos(rot_angle)   sin(rot_angle); -sin(rot_angle)  cos(rot_angle)];
            xy_new = R * (xy_all - [bbox(1); bbox(2)]) + [bbox(1); bbox(2)];
            
            for i = 1:size(xy_new,2)
               im_mod(xy_new(2,i), xy_new(1,i), :) = im_frame(xy_all(2,i), xy_all(1,i), :);
            end
            
        end
    end
    
end