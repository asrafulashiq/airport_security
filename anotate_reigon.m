function []=anotate_reigon(filename, region_num)
im=imread(filename);
figure;
imshow(im);
h=imrect;
eval(['region_pos' num2str(region_num) '=getPosition(h);']);
eval(['save region_pos' num2str(region_num) ' region_pos' num2str(region_num)]);

end