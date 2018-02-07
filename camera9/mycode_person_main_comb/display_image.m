function image = display_image(im_c, R_9)

global scale;

%% decorate text
font_size_im = 40 * scale;

%% bin
%im_c = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % bin region

bin_array = R_9.R_bin.bin_array;

for i = 1:numel(bin_array)
    bounding_box = [ bin_array{i}.BoundingBox(1) + R_9.R_bin.reg(1) ...
        bin_array{i}.BoundingBox(2) + R_9.R_bin.reg(3) ...
        bin_array{i}.BoundingBox(3) ...
        bin_array{i}.BoundingBox(4) ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('bin:%d', bin_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);   
end

%% people
%im_c = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region

people_array = R_9.R_people.people_array;

for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1) + R_9.R_people.reg(1) ...
        people_array{i}.BoundingBox(2) + R_9.R_people.reg(3) ...
        people_array{i}.BoundingBox(3) ...
        people_array{i}.BoundingBox(4) ];
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    text_ = sprintf('person:%d', people_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

figure(2);
imshow(im_c);
title(sprintf('%04d',R_9.current_frame));
drawnow;

F = getframe(gcf);
image=F.cdata;

end