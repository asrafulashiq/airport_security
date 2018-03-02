function CLASP_extractFrames_withPreprocess( video_dir,frames_dir,rate,type,scale)
%   video_dir: direction of video
%   frames_dir: direction of saving imgs
%   rate: extract one for every %rate frames
%   type: to decide which crop and rotation parameter to be chosen,
%       currently only for '09_5AC9' or '09_5AC11'
%   scale: scale to resize image

v = VideoReader(video_dir);
if ~exist(frames_dir)
    mkdir(frames_dir);
end

crop = containers.Map;
crop('09_5AC9') =  [660  336   730  1738]*scale;
crop('09_5AC11') =  [ 230  150  730  1738]*scale;
rotation = containers.Map;
rotation('09_5AC9') = 102;
rotation('09_5AC11') = 90;

i = 0;
while hasFrame(v)
    img = readFrame(v);
    img = imresize(img,scale);
    img = imrotate(img, rotation(type));
    img = imcrop(img, crop(type));
    
    disp(v.CurrentTime/v.Duration)
    if i < 10
        str = ['000',num2str(i)];
    end
    if i >= 10 && i < 100
       str = ['00',num2str(i)]; 
    end
    if i >= 100 && i < 1000
        str = ['0',num2str(i)];
    end
    if i >= 1000
        str = num2str(i);
    end
    if mod(i,rate) == 0
        imwrite(img,[frames_dir,'/',type,'_Frame',str,'.jpg']);
    end
    i = i+1;
end
v.CurrentTime = 0;

