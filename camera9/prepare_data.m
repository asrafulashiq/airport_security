clear all;
close all;
input_name='./Experi1A/camera9_1A.mp4';
output_name='./Experi1A/output_c9.avi';
path='./Experi1A/';
get_back2(input_name,200);
%get_back(filename,1);
anotate_reigon([input_name(1:end-4) '_back.jpg'], path,'1');
anotate_reigon([input_name(1:end-4) '_back.jpg'], path,'4');
%%
% load region_pos_c9_1;
% load region_pos_c9_2;
% 
% r1=[round(region_pos_c9_1(1)) round(region_pos_c9_1(3)+region_pos_c9_1(1)) ...
%     round(region_pos_c9_1(2)) round(region_pos_c9_1(4)+region_pos_c9_1(2))];
% im=imread([filename(1:end-4) '_back.jpg']);
% im_r=im(r1(3):r1(4),r1(1):r1(2),:);
% imwrite(im_r, 'region_c9_1.jpg');
% 
% figure;
% hAxes = axes();
% imageHandle = imshow(im_r);
% set(imageHandle,'ButtonDownFcn',@ImageClickCallback);
% 
% function ImageClickCallback ( objectHandle , eventData )
% axesHandle  = get(objectHandle,'Parent');
% coordinates = get(axesHandle,'CurrentPoint'); 
% coordinates = coordinates(1,1:2);
% message     = sprintf('x: %.1f , y: %.1f',coordinates (1) ,coordinates (2));
% helpdlg(message);
% end