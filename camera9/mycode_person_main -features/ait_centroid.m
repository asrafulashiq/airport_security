function centroid = ait_centroid(I, bbox)

pic = I(bbox(2): bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1);

reg = regionprops(pic, 'Centroid','Area');

if isempty(reg)

    centroid = [];
else
    reg = reg([reg.Area]==max([reg.Area]));
    centroid = reg.Centroid + double([bbox(1)  bbox(2)]);

end

% [~,~,z] = size(pic);          % Checking whether the picture is colored or monochromatic, if colored then converting to gray.
% if (z ~= 1)
%     pic = rgb2gray(pic);
% end
% 
% 
% im = pic;
% [rows,cols] = size(im);
% r = ones(rows,1)*[1:cols];    % Matrix with each pixel set to its x coordinate
% c = [1:rows]'*ones(1,cols);   %   "     "     "    "    "  "   "  y    "
% 
% area = sum(sum(im));
% mean_r = sum(sum(double(im).*r))/area + bbox(2);
% mean_c = sum(sum(double(im).*c))/area + bbox(1);
% centroid = [mean_c,mean_r];