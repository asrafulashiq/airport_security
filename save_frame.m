filename='121431_rec_cam_000.mp4';
v = VideoReader(filename);
index=10055;
use_index=[];
black=zeros(480,272,3);
% max_f=v.NumberOfFrames;
max_f=10077;
while(index<=max_f)
frame = read(v,index);
frame = imresize(frame,0.25);
frame = imrotate(frame,-90);
% figure;
% imshow(frame);
finish=index
[M,F] = mode(frame(:));
% if (M<10 &&  F>=0.4*480*272*3)
%     index=index+1;
%     continue
% end
imwrite(frame,['./jpg_folder/' filename(1:end-4) num2str(index) '.jpg']);
use_index=[use_index index];
index=index+1;
end