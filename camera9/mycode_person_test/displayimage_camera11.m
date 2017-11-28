function image = displayimage_camera11(im_c, R_belt, R_dropping, bin_array, people_array, bin_seq, people_seq)
global scale;
%% decorate text
global k_distort;
%im_c = lensdistort(im_c, k_distort);
font_size = 50 * scale;
text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);
font_size_im = 40 * scale;
t_width = size(text_im, 2);
t_height = size(text_im, 1);

unspec_color = 'red';
right_color = 'green';
wrong_color = 'red';

t_pad_x = t_width * 0.05;
t_pad_y = t_height * 0.1;

b_strt_x = t_pad_x;
b_strt_y = t_pad_y;
p_strt_x = t_width / 2 + t_pad_x;
p_strt_y = t_pad_y;

font_box_height = font_size * 1.3;
text_im = insertText(text_im, [b_strt_x  b_strt_y], 'B-seq', 'AnchorPoint', 'LeftBottom', ...
    'FontSize', font_size, 'BoxOpacity', 0.3);
text_im = insertText(text_im, [p_strt_x  p_strt_y], 'P-seq', 'AnchorPoint', 'LeftBottom', ... 
    'FontSize', font_size, 'BoxOpacity', 0.3);

offsetx = 0;
offsety = 0;
%%% annotate main image
%% plot bin
for i=1:size(bin_array,2)
    if bin_array{i}.in_flag==1
        
        bounding_box = [ bin_array{i}.BoundingBox(1)+R_belt.r4(1) + 3*offsetx ...
                         bin_array{i}.BoundingBox(2)+R_belt.r4(3) + offsety...
                         bin_array{i}.BoundingBox(3)-4*offsetx ...
                         bin_array{i}.BoundingBox(4)-2*offsety ];
        if bin_array{i}.match=="unspec"
            color = unspec_color;
        elseif bin_array{i}.match=="right"
            color = right_color;
        else
            color = wrong_color;
        end
        im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, ...
                            'Opacity', 0.3);
        im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', color);
       
        text_ = sprintf('b:%d\np:%d',bin_array{i}.label, bin_array{i}.belongs_to);
        im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
        
    end
end

%% draw people
for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1)+R_dropping.r1(1)+offsetx ...
                     people_array{i}.BoundingBox(2)+R_dropping.r1(3)+offsety ...
                     people_array{i}.BoundingBox(3)-2*offsetx ...
                     people_array{i}.BoundingBox(4)-2*offsety ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'blue', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'blue');
    
   
end


%% text
for i = 1:size(bin_seq, 2)
    text_im = insertText(text_im, [b_strt_x b_strt_y+i*t_pad_y], sprintf('b%d', bin_seq{i}.label), ...
        'AnchorPoint', 'LeftBottom', 'FontSize', font_size, 'BoxOpacity', 0.3);
end

for i = 1:size(people_seq, 2)
    text_im = insertText(text_im, [p_strt_x p_strt_y+i*t_pad_y], sprintf('p%d', people_seq{i}.label), ...
        'AnchorPoint', 'LeftBottom', 'FontSize', font_size, 'BoxOpacity', 0.3);    
end


%% plot 
figure(1);
imshow(im_c);
%imshow([im_c text_im]);
drawnow;

F = getframe(gcf);
image=F.cdata;


end