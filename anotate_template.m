function []=anotate_template(filename, frame, region_num)
v = VideoReader(filename);
im = read(v,frame);
im = imresize(im,0.25);
im = imrotate(im,-90);
figure;
imshow(im);
h=imrect;
region_pos=getPosition(h);
r1=[round(region_pos(1)) round(region_pos(3)+region_pos(1)) ...
    round(region_pos(2)) round(region_pos(4)+region_pos(2))];

template=im(r1(3):r1(4),r1(1):r1(2),:);
save_name=['template' num2str(region_num) '.jpg'];
imwrite(template,save_name);
end