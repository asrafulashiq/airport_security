function my_box_match_fun(imb,properties)

im_crop = imcrop(imb, properties.BoundingBox);

bin_reg = regionprops(im_crop,'BoundingBox', 'Orientation','Centroid','Area');
areas= [bin_reg.Area];
bin_reg = bin_reg(areas==max(areas));

centr = bin_reg.Centroid - [bin_reg.BoundingBox(1) bin_reg.BoundingBox(2)];
theta = -bin_reg.Orientation;

% create rectangle
W = 160;
H = 120;
im_rec = ones(H,W);
[row,col] = find(im_rec);
row = row - H/2;
col = col - W/2;
xy = [col'; row'];

% create transformation matrix
rotmat = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
translation = [centr(1); centr(2)];
xy_t = round(rotmat * xy + translation);

im_new = zeros(size(im_crop,1), size(im_crop,2), 3);

indices = [];
for i=1:size(xy_t,2)
    try
        idx = sub2ind(size(im_crop), xy_t(2,i), xy_t(1,i));
        indices(end+1) = idx;
        im_new(xy_t(2,i),xy_t(1,i),1) = 255;
    catch
        
    end
end

val = (sum(im_crop(indices)) - sum(im_crop(indices)==0)) / sum(im_rec(:));

end