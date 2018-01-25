function im = get_im_13(videopath, para)

seq = para.pseq ;
img = imread(fullfile(seq.path_13, sprintf('%04i.jpg', para.curF - 36)));
im = imresize(img,seq.scale);%original image
im = imrotate(im, seq.rot_angle);
if seq.k_distort_11~=0
    im = lensdistort(im, seq.k_distort_11);
end
r4 = seq.r4_13;
im = im(r4(3):r4(4),r4(1):r4(2),:);

end