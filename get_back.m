function []=get_back(filename,back_index)
v = VideoReader(filename);
frame = read(v,back_index);

frame = imresize(frame,0.25);
frame = imrotate(frame,-90);
figure;
imshow(frame);
imwrite(frame,[filename(1:end-4) '_back.jpg']);
end
