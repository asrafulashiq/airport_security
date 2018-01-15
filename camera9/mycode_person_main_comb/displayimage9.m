function image = displayimage9(im_c, R_bin, R_people, bin_array, people_array)
global scale;
%% decorate text
font_size = 50 * scale;
font_size_im = 40 * scale;
text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);

t_width = size(text_im, 2);
t_height = size(text_im, 1);

t_pad_x = t_width * 0.05;
t_pad_y = t_height * 0.03;

b_strt_x = t_pad_x;
b_strt_y = t_pad_y;
p_strt_x = t_width / 2 + t_pad_x;
p_strt_y = t_pad_y;

%font_box_height = font_size * 1.3;
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
        
        bounding_box = [ bin_array{i}.BoundingBox(1)+R_bin.r4(1) + 3*offsetx ...
            bin_array{i}.BoundingBox(2)+R_bin.r4(3) + offsety...
            bin_array{i}.BoundingBox(3)-4*offsetx ...
            bin_array{i}.BoundingBox(4)-2*offsety ];
        
        im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', ...
            'Opacity', 0.3);
        im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', 'red');
        if bin_array{i}.belongs_to ~= -1
            text_ = sprintf('bin:%d\nperson:%d',bin_array{i}.label, bin_array{i}.belongs_to);
        else
            text_ = sprintf('bin:%d',bin_array{i}.label);
            
        end
        im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
        
    end
end

%% draw people
for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1)+R_people.r1(1)+offsetx ...
        people_array{i}.BoundingBox(2)+R_people.r1(3)+offsety ...
        people_array{i}.BoundingBox(3)-2*offsetx ...
        people_array{i}.BoundingBox(4)-2*offsety ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('person:%d', people_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

%% text
% for i = 1:size(bin_seq, 2)
%     text_im = insertText(text_im, [b_strt_x b_strt_y+i*t_pad_y], sprintf('b%d', bin_seq{i}.label), ...
%         'AnchorPoint', 'LeftBottom', 'FontSize', font_size, 'BoxOpacity', 0.3);
% end
%
% for i = 1:size(people_seq, 2)
%     text_im = insertText(text_im, [p_strt_x p_strt_y+i*t_pad_y], sprintf('p%d', people_seq{i}.label), ...
%         'AnchorPoint', 'LeftBottom', 'FontSize', font_size, 'BoxOpacity', 0.3);
% end

%% plot
figure(1);
%imshow([im_c text_im]);
imshow(im_c);
drawnow;

F = getframe(gcf);
image=F.cdata;

end