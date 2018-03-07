function image = display_image_2(im_c, R_2, f)

global scale;

%% decorate text
font_size_im = 80 * scale;

color_arr = {'blue', 'green', 'cyan', 'magenta', 'black'};


%% people
%im_c = im_c(R_2.R_people.reg(3):R_2.R_people.reg(4),R_2.R_people.reg(1):R_2.R_people.reg(2),:); % people region

people_array = R_2.R_people.people_array;

for i = 1:size(people_array, 2)
%     bounding_box = [ people_array{i}.BoundingBox(1) + R_2.R_people.reg(1) ...
%         people_array{i}.BoundingBox(2) + R_2.R_people.reg(3) ...
%         people_array{i}.BoundingBox(3) ...
%         people_array{i}.BoundingBox(4) ];

bounding_box = people_array{i}.BoundingBox;

         color = color_arr(people_array{i}.label);

    
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', color);
    text_ = sprintf('P%d', people_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

if nargin > 2 && f ~= 0
figure(1);
imshow(im_c);
title(sprintf('%04d',R_2.current_frame));
drawnow;
end

image = im_c;

end