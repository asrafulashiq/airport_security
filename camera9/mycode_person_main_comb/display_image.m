function display_image(im_c, R_9)

global scale;

%% decorate text
font_size_im = 40 * scale;



%% people
im_r = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region

people_array = R_9.R_people.people_array;

for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1) ...
        people_array{i}.BoundingBox(2) ...
        people_array{i}.BoundingBox(3) ...
        people_array{i}.BoundingBox(4) ];
    im_r = insertShape(im_r, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_r = insertShape(im_r, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('person:%d', people_array{i}.label);
    im_r = insertText(im_r, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

figure(1);
imshow(im_r);
title(sprintf('%04d',R_9.current_frame));
drawnow;


end