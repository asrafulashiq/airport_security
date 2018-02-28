function exp_hand(im_c, im_flow_all, R_9)

reg = R_9.exp_reg;
im_flow = im_flow_all(reg(3):reg(4), reg(1):reg(2),:);

im_flow_g = rgb2gray(im_flow);
im_flow_hsv = rgb2hsv(im_flow);

im_filtered = imgaussfilt(im_flow_g, 3);
im_tmp = im_filtered;
im_filtered(im_filtered < 35) = 0;

% close operation for the image
se = strel('disk',7);
im_closed = imclose(im_filtered,se);
im_binary = logical(im_closed); %extract people region
im_binary = imfill(im_binary, 'holes');

figure(3);imshow(im_binary);

end