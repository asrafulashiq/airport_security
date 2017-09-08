clear all;
filename='out.avi';
%get_back(filename,1);
anotate_reigon([filename(1:end-4) '_back.jpg'], 1);
anotate_reigon([filename(1:end-4) '_back.jpg'], 2);
load region_pos1 
load region_pos2 

eval(['pos=region_pos' num2str(1)]);
r1=[round(region_pos1(1)) round(region_pos1(3)+region_pos1(1)) ...
    round(region_pos1(2)) round(region_pos1(4)+region_pos1(2))];
im=imread([filename(1:end-4) '_back.jpg']);
im_r=im(r1(3):r1(4),r1(1):r1(2),:);
imwrite(im_r, 'region_1.jpg');