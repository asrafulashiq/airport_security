function im_c = displayimage11_13_people(im_c, people_array, camera_no)
global scale;

%% decorate text
font_size_im = 40 * scale;
text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);

t_width = size(text_im, 2);
t_height = size(text_im, 1);

t_pad_x = t_width * 0.05;
t_pad_y = t_height * 0.03;



offsetx = 0;
offsety = 0;
%%% annotate main image
%% plot people

%% draw people

for i = 1:numel(people_array)
    bounding_box = [ people_array{i}.BoundingBox(1)+offsetx ...
        people_array{i}.BoundingBox(2)+offsety ...
        people_array{i}.BoundingBox(3)-2*offsetx ...
        people_array{i}.BoundingBox(4)-2*offsety ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('person:%d', people_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end
%im_c = lensdistort(im_c, -k_dist);


end