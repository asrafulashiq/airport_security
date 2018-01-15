function im_background = get_background(filename, count)

k = 1;
im_back = 0;
while k <= count
    fname = fullfile(filename, sprintf('%04i.jpg',k));
    im_frame = imread(fname);
    im_back = im_back + double(im_frame);
    
    k = k + 1;
end

im_back = im_back /  count;

im_background = uint8(im_back);

end