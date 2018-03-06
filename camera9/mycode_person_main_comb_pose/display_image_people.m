function image = display_image_people(im_r, R_9)

global scale;

%% decorate text
font_size_im = 40 * scale;

%% people

people_array = R_9.R_people.people_array;

for i = 1:numel(people_array)
    bounding_box = people_array{i}.BoundingBox;
    im_r = insertShape(im_r, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_r = insertShape(im_r, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('people:%d', people_array{i}.label);
    im_r = insertText(im_r, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

figure(11);
imshow(im_r);
title(sprintf('%04d',R_9.current_frame));
drawnow;

image=im_r;


end