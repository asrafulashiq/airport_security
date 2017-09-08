%%
load region_pos_c9_1;
load region_pos_c9_2;

r1=[round(region_pos_c9_1(1)) round(region_pos_c9_1(3)+region_pos_c9_1(1)) ...
    round(region_pos_c9_1(2)) round(region_pos_c9_1(4)+region_pos_c9_1(2))];
im=imread([filename(1:end-4) '_back.jpg']);
im_r=im(r1(3):r1(4),r1(1):r1(2),:);
imwrite(im_r, 'region_c9_1.jpg');

figure;
hAxes = axes();
imageHandle = imshow(im_r);
set(imageHandle,'ButtonDownFcn',@ImageClickCallback);

function ImageClickCallback ( objectHandle , eventData )
axesHandle  = get(objectHandle,'Parent');
coordinates = get(axesHandle,'CurrentPoint'); 
coordinates = coordinates(1,1:2);
message     = sprintf('x: %.1f , y: %.1f',coordinates (1) ,coordinates (2));
helpdlg(message);
end