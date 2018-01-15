function features = get_features_2(I, bbox, im_binary )

bbox = int32(bbox);
img = I(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);

Ilab = rgb2lab(img);
Ilab = imresize(Ilab, 1/16);

[Mr,Nr,~] = size(Ilab);    
colorFeatures = reshape(Ilab, Mr*Nr, []); 

rowNorm = sqrt(sum(colorFeatures.^2,2));
colorFeatures = bsxfun(@rdivide, colorFeatures, rowNorm + eps);


if ~isempty(im_binary)
    mask = double(im_binary(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :));
else
    mask = ones(bbox(4), bbox(3));
end

num_bins = 100;
%mask = double(mask);

im_conv = rgb2hsv(img);

im1 = im_conv(:,:,1) .* mask;
im2 = im_conv(:,:,2) .* mask;
im3 = im_conv(:,:,3) .* mask;

h1 = histcounts(im1, num_bins);
h1(1) = 0;
h1 = h1 / sum(h1);
h2 = histcounts(im2, num_bins);
h2(1) = 0;
h2 = h2 / sum(h2);
h3 = histcounts(im3, num_bins);
h3(1) = 0;
h3 = h3 / sum(h3);
features = [h1;h2;h3];      
         
end