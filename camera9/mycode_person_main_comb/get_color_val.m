function color_val = get_color_val(I, bbox,mask_all)
bbox = int32(bbox);
img = I(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);
mask = mask_all(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);

% r_mean = mean(mean(img(:,:,1) .* mask));
% g_mean = mean(mean(img(:,:,2) .* mask));
% b_mean = mean(mean(img(:,:,3) .* mask));
% 
% color_val = [r_mean, g_mean, b_mean];

%im_total = double( 0.33 * img(:,:,1) + 0.33 * img(:,:,2) + 0.33 * img(:,:,3) );
%black_indices = find(im_total < 30);

img = rgb2hsv(img);

num_bins = 10;

im_1 = img(:,:,1) .* mask;
im_2 = img(:,:,2) .* mask;
%im_3 = img(:,:,3) .* mask;

%im_red(black_indices) = 0; im_green(black_indices) = 0; im_blue(black_indices) = 0;
% color_val = [];
h1 = histcounts(im_1, num_bins, 'BinLimits',[0 1], 'Normalization', 'probability');
%h1(1:30) = 0;
h2 = histcounts(im_2, num_bins, 'BinLimits',[0 1], 'Normalization', 'probability');
%h2(1:30) = 0;
%h3 = histcounts(im_3, num_bins, 'BinLimits',[0 1], 'Normalization', 'probability');
%h3(1:30) = 0;
color_val = [h1 h2];

end