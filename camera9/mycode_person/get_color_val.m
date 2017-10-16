function color_val = get_color_val(I, bbox,mask_all)
bbox = int32(bbox);
img = I(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);
mask = uint8(mask_all(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :));
% r = 0; g = 0; b = 0;
% r_c = 0; g_c = 0; b_c = 0;

% img(:,:,1) = img(:,:,1) .* mask;
% img(:,:,2) = img(:,:,2) .* mask;
% img(:,:,3) = img(:,:,3) .* mask;
% 
% for i=1:size(img,1)
%     for j=1:size(img,2)
%         if mask(i,j) && mean(img(i,j,:)) > 10 % avoid black portion
%             r = r + double(img(i,j,1)); r_c = r_c + 1;
%             g = g + double(img(i,j,2)); g_c = g_c + 1;
%             b = b + double(img(i,j,3)); b_c = b_c + 1;
%         end
%     end
% end

r_mean = mean(mean(img(:,:,1) .* mask));
g_mean = mean(mean(img(:,:,2) .* mask));
b_mean = mean(mean(img(:,:,3) .* mask));

% r_mean = r / r_c;
% g_mean = g / g_c;
% b_mean = b / b_c;

color_val = [r_mean, g_mean, b_mean];

end