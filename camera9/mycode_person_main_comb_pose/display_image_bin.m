function img = display_image_bin(im_r, R_9)

global scale;

%% decorate text
font_size_im = 40 * scale;

%% bin
%im_r = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % bin region

bin_array = R_9.R_bin.bin_array;

for i = 1:numel(bin_array)
    bounding_box = bin_array{i}.BoundingBox;
    im_r = insertShape(im_r, 'FilledRectangle', bounding_box, 'Color', 'red', 'opacity', 0.2);
    if bounding_box(2) > 305
        im_r = insertShape(im_r, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'green');
    else
        im_r = insertShape(im_r, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', 'red');
    end
    text_ = sprintf('bin:%d', bin_array{i}.label);
    im_r = insertText(im_r, bounding_box(1:2), text_, 'FontSize', font_size_im);   
end

figure(1);
imshow(im_r);
title(sprintf('%04d',R_9.current_frame));
drawnow;

img = im_r;

end