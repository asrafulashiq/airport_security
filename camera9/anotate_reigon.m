function []=anotate_reigon(filename, path,num)
im=imread(filename);
I  = rgb2gray(im);
figure;
imshow(im);
h=imrect;
pos=getPosition(h);
r=[round(pos(1)) round(pos(3)+pos(1)) ...
    round(pos(2)) round(pos(4)+pos(2))];
eval(['r' num '=r']);
matname = fullfile(path, ['r' num '.mat']);
save(matname, ['r' num])

end