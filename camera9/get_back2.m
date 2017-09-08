function []=get_back2(filename,back_index)
v = VideoReader(filename);
frame = read(v,back_index);

frame = imresize(frame,0.25);
frame = imrotate(frame,-70+170);
figure;
imshow(frame);
imwrite(frame,[filename(1:end-4) '_back.jpg']);
end



