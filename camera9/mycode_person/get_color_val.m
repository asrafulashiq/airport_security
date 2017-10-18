function color_val = get_color_val(I, bbox,mask_all)
bbox = int32(bbox);
img = I(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);
mask = uint8(mask_all(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :));

% r_mean = mean(mean(img(:,:,1) .* mask));
% g_mean = mean(mean(img(:,:,2) .* mask));
% b_mean = mean(mean(img(:,:,3) .* mask));
% 
% color_val = [r_mean, g_mean, b_mean];

im_total = double( 0.33 * img(:,:,1) + 0.33 * img(:,:,2) + 0.33 * img(:,:,3) );
black_indices = find(im_total < 30);

num_bins = 255;

im_red = img(:,:,1) .* mask;
im_green = img(:,:,2) .* mask;
im_blue = img(:,:,3) .* mask;

im_red(black_indices) = 0; im_green(black_indices) = 0; im_blue(black_indices) = 0;
color_val = [];
h1 = histogram(im_red, num_bins);
color_val = [color_val; h1.Values];
h2 = histogram(im_green, num_bins);
color_val = [color_val; h2.Values];
h3 = histogram(im_blue, num_bins);
color_val = [color_val; h3.Values];

%color_val = [h1.Values;h2.Values;h3.Values];

end