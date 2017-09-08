clear all;
load region_pos2;
% filename='template1.jpg';
filename='template2.jpg';
vname='out.avi';
v = VideoReader(vname);
%%
% anotate_template(filename, frame, region_num)
frame =read(v,3500);
%10740
frame = imresize(frame,0.25);
frame = imrotate(frame,-90);
r1=[round(region_pos2(1)) round(region_pos2(3)+region_pos2(1)) ...
    round(region_pos2(2)) round(region_pos2(4)+region_pos2(2))];
frame_region=imread('region_2.jpg');
%imwrite(frame_region,'region_2.jpg');
figure;
cut=0;
imshow(frame_region(1:end-cut,:));
im=imread(filename);
%%
% htm=vision.TemplateMatcher;
% % hmi = vision.MarkerInserter('Size',10, ...
% % 'Fill',true,'FillColor','White','Opacity',0.75);
% Loc=step(htm,rgb2gray(frame),rgb2gray(im));
% pos_x=Loc(1)-2:Loc(1)+2;
% pos_y=Loc(2)-2:Loc(2)+2;
% frame(pos_x,pos_y,1)=255;
% %J = step(hmi,frame,Loc);
% figure;
% imshow(frame);
% title('Marked target');

% bw=edge(rgb2gray(im),'Canny');
% figure;
% imshow(bw,[]);
% bw2=edge(rgb2gray(frame_region),'Canny');
% figure;
% imshow(bw2,[]);

pos=[1 11 83 53+11;1 63 83 53+63];
% r1_obj=[42 36.7861404603658 4426.66666666667 1 1;
%     42 140.962588047764 4426.66666666667 2 1;
%     42 90.5000000000000 4426.66666666667 3 1];
r1_obj=[42 94.5176698692970 4772.50000000000 3 1;
    42 39.2500000000000 4772.50000000000 4 1];
% r1_obj=[42 86.6676270591732 4316 1 1;42 36.5000000000000 4316 3 1];

im_channel=rgb2gray(frame_region);
r1_cnt=size(r1_obj,1);
tic;
blob=zeros(1,r1_cnt);
edge_im=edge(im_channel,'canny',0.25);
for i=1:r1_cnt
    blob(i)=sum(sum(edge_im(round(r1_obj(i,2)-35):round(r1_obj(i,2)+35),:)));
end
no=find(blob==min(blob));
toc;
figure;
imshowpair(edge_im,frame_region,'montage');
%%
tic;
%edge_im=edge(rgb2gray(frame_region),'canny',0.25);
for i=1:size(r1_obj,1)
    edge_im=edge(im_channel(round(r1_obj(i,2)-35):round(r1_obj(i,2)+35),:),'canny',0.25);
    blob(i)=sum(sum(edge_im));
end
no=find(blob==min(blob));
toc;
figure;
imshowpair(edge_im,frame_region,'montage');
%%
c = normxcorr2(rgb2gray(im),rgb2gray(frame_region));
figure;
threshold=0.5;

c(c>threshold)=1;
c(c<=threshold)=0;

care=c(int16(size(im,1)/2):end-int16(size(im,1)/2),int16(size(im,2)/2):end-int16(size(im,2)/2));
imshow(care,[]);
for i=1:size(frame_region,2)
frame_region(care(:,i)>0,:)=0;
end
figure;
imshow(care,[]);
figure;
imshow(frame_region,[]);

% figure;
% imshow(c1,[]);
%%
frame =read(v,3650);
frame = imresize(frame,0.25);
frame = imrotate(frame,-90);
move2=5;
move1=7;
r1=[round(region_pos2(1)) round(region_pos2(3)+region_pos2(1)) ...
    round(region_pos2(2)) round(region_pos2(4)+region_pos2(2))];
frame_region=frame(r1(3):r1(4),r1(1)-move1:r1(2)-move2,:);
edge_im=edge(rgb2gray(frame_region),'canny',0.2);
% se = strel('disk',16);
% im_close=imclose(edge_im,se);
[H,T,R] = hough(edge_im);
P  = houghpeaks(H,20,'threshold',ceil(0.5*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
lines = houghlines(edge_im,T,R,P,'FillGap',4,'MinLength',40);
%show the figure
close all;
imshow(H,[],'XData',T,'YData',R,...
            'InitialMagnification','fit');
xlabel('\theta'), ylabel('\rho');
axis on, axis normal, hold on;

plot(x,y,'s','color','white');
figure;
imshow(frame_region);hold on;
% max_len = 0;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

%    % Determine the endpoints of the longest line segment
%    len = norm(lines(k).point1 - lines(k).point2);
%    if ( len > max_len)
%       max_len = len;
%       xy_long = xy;
%    end
end
m_p=zeros(length(lines),length(lines),2);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   if k<length(lines)
       for j= k+1:length(lines)
           xy2 = [lines(j).point1; lines(j).point2];
           m_p(k,j,:)=(xy(1,:)+xy(1,:)+xy2(1,:)+xy2(2,:))/4;
           plot(m_p(k,j,1),m_p(k,j,2),'x','LineWidth',2,'Color','red');
       end
   end
end
figure;
imshowpair(edge_im,frame_region,'montage');

%%
If = imfill(edge_im, 'holes');
figure;
imshowpair(edge_im,If,'montage');