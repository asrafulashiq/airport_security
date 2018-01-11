function image = displayimage_camera11_13(im_11, im_13, R_11, R_13)
global scale;
%% decorate text
global k_distort;
%im_c = lensdistort(im_c, k_distort);
%font_size = 50 * scale;
%text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);
font_size_im = 40 * scale;
%t_width = size(text_im, 2);
%t_height = size(text_im, 1);

unspec_color = 'red';
right_color = 'green';
wrong_color = 'red';

% t_pad_x = t_width * 0.05;
% t_pad_y = t_height * 0.1;

% b_strt_x = t_pad_x;
% b_strt_y = t_pad_y;
% p_strt_x = t_width / 2 + t_pad_x;
% p_strt_y = t_pad_y;

% font_box_height = font_size * 1.3;
%text_im = insertText(text_im, [b_strt_x  b_strt_y], 'B-seq', 'AnchorPoint', 'LeftBottom', ...
%   'FontSize', font_size, 'BoxOpacity', 0.3);
%text_im = insertText(text_im, [p_strt_x  p_strt_y], 'P-seq', 'AnchorPoint', 'LeftBottom', ...
%  'FontSize', font_size, 'BoxOpacity', 0.3);

offsetx = 0;
offsety = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot 11 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

im_c = im_11;

%% plot bin
for i=1:size(R_11.bin_array,2)
    if R_11.bin_array{i}.in_flag==1
        
        bounding_box = [ R_11.bin_array{i}.BoundingBox(1)+R_11.R_bin.r4(1) + 3*offsetx ...
            R_11.bin_array{i}.BoundingBox(2)+R_11.R_bin.r4(3) + offsety...
            R_11.bin_array{i}.BoundingBox(3)-4*offsetx ...
            R_11.bin_array{i}.BoundingBox(4)-2*offsety ];
        if R_11.bin_array{i}.match=="unspec"
            color = unspec_color;
        elseif R_11.bin_array{i}.match=="right"
            color = right_color;
        else
            color = wrong_color;
        end
        im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, ...
            'Opacity', 0.3);
        im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', color);
        
        if R_11.bin_array{i}.belongs_to ~= -1
            text_ = sprintf('b:%d\np:%d',R_11.bin_array{i}.label, R_11.bin_array{i}.belongs_to);
        else
            text_ = sprintf('b:%d',R_11.bin_array{i}.label);
        end
        im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);       
    end
end

%% draw people
for i = 1:size(R_11.people_array, 2)
    bounding_box = [ R_11.people_array{i}.BoundingBox(1)+R_11.R_people.r1(1)+offsetx ...
        R_11.people_array{i}.BoundingBox(2)+R_11.R_people.r1(3)+offsety ...
        R_11.people_array{i}.BoundingBox(3)-2*offsetx ...
        R_11.people_array{i}.BoundingBox(4)-2*offsety ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'blue', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'blue');
    text_ = sprintf('person:%d', R_11.people_array{i}.id);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

im_11 = im_c;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot 13 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag = 0;


if ~isempty(R_13)
    
    im_c = im_13;
      
    %% plot bin
    for i=1:size(R_13.bin_array,2)
        if R_13.bin_array{i}.in_flag==1
            
            bounding_box = [ R_13.bin_array{i}.BoundingBox(1)+R_13.R_bin.r4(1) + 3*offsetx ...
                R_13.bin_array{i}.BoundingBox(2)+R_13.R_bin.r4(3) + offsety...
                R_13.bin_array{i}.BoundingBox(3)-4*offsetx ...
                R_13.bin_array{i}.BoundingBox(4)-2*offsety ];
            if R_13.bin_array{i}.match=="unspec"
                color = unspec_color;
            elseif R_13.bin_array{i}.match=="right"
                color = right_color;
            else
                color = wrong_color;
            end
            im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, ...
                'Opacity', 0.3);
            im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', color);
            
            if R_13.bin_array{i}.belongs_to ~= -1
                text_ = sprintf('b:%d\np:%d',R_13.bin_array{i}.label, R_13.bin_array{i}.belongs_to);
            else
                text_ = sprintf('b:%d',R_13.bin_array{i}.label);
            end
            im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
            flag = 1;
        end
    end
    
    %% draw people
    for i = 1:size(R_13.people_array, 2)
        bounding_box = [ R_13.people_array{i}.BoundingBox(1)+R_13.R_people.r1(1)+offsetx ...
            R_13.people_array{i}.BoundingBox(2)+R_13.R_people.r1(3)+offsety ...
            R_13.people_array{i}.BoundingBox(3)-2*offsetx ...
            R_13.people_array{i}.BoundingBox(4)-2*offsety ];
        im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'blue', 'opacity', 0.2);
        im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'blue');
        text_ = sprintf('person:%d', R_13.people_array{i}.id);
        im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
        flag = 1;
    end
    
    im_13 = im_c;
    
end

%% plot
figure(1);

h = size(im_11,1);
w = size(im_11,2);

if flag && ~isempty(im_13)
    %im_13 = imresize(im_13, [size(im_11, 1) size(im_11,2)]);
    %im_11 = imresize(im_11, [size(im_11, 1) size(im_11,2)]);
    imshow([im_11 im_13]);
else
    z = uint8(zeros(h,w,3));
    z(:) = 255;
    imshow([im_11 z]);
end
%imshow([im_c text_im]);
drawnow;

F = getframe(gcf);
image=F.cdata;


end