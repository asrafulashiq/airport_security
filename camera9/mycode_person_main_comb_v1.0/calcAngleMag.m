function [mean_angle, mean_flow] = calcAngleMag(im_hsv, im_binary, b_b)

offset_x = b_b(3) * 0.1;
offset_y = b_b(4) * 0.1;

bb(1:2) = b_b(1:2) + [offset_x offset_y];
bb(3:4) = b_b(3:4) - 2*[offset_x offset_y];

im = imcrop(im_hsv, bb);
mask = imcrop(im_binary, bb);
    
im_m = im .* mask;

angle_reg = im_m(:,:,1);
mag_reg = im_m(:,:,3);

mean_angle = sum(angle_reg(:) .* mag_reg(:)) / sum(mag_reg(:));
mean_angle = mean_angle * 180 * 2;

mean_flow = mean(mag_reg(:));

end