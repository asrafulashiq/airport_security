%%
clear all;
load region_pos2;
filename='template1.jpg';
vname='out.avi';
v = VideoReader(vname);
frame =read(v,3650);
frame = imresize(frame,0.25);
frame = imrotate(frame,-90);
move2=5;
move1=7;
r1=[round(region_pos2(1)) round(region_pos2(3)+region_pos2(1)) ...
    round(region_pos2(2)) round(region_pos2(4)+region_pos2(2))];
%frame_region=frame(r1(3):r1(4),r1(1)-move1:r1(2)-move2,:);
frame_region=frame(r1(3):r1(4),r1(1):r1(2),:);
edge_im=edge(rgb2gray(frame_region),'canny',0.2);
% se = strel('disk',16);
% im_close=imclose(edge_im,se);
tic;
[H,T,R] = hough(edge_im);
P  = houghpeaks(H,20,'threshold',ceil(0.5*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
lines = houghlines(edge_im,T,R,P,'FillGap',4,'MinLength',40);
%show the figure
% close all;
% imshow(H,[],'XData',T,'YData',R,...
%             'InitialMagnification','fit');
% xlabel('\theta'), ylabel('\rho');
% axis on, axis normal, hold on;
% 
% plot(x,y,'s','color','white');

% % max_len = 0;
% for k = 1:length(lines)
%    xy = [lines(k).point1; lines(k).point2];
%    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
% 
%    % Plot beginnings and ends of lines
%    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%    plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
% 
% %    % Determine the endpoints of the longest line segment
% %    len = norm(lines(k).point1 - lines(k).point2);
% %    if ( len > max_len)
% %       max_len = len;
% %       xy_long = xy;
% %    end
% end
m_p=zeros(length(lines),length(lines),2);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   if k<length(lines)
       for j= k+1:length(lines)
           xy2 = [lines(j).point1; lines(j).point2];
           m_p(k,j,:)=(xy(1,:)+xy(2,:)+xy2(1,:)+xy2(2,:))/4;
       end
   end
end
mid_rect=[];
for k = 1:length(lines)
   if k<length(lines)
       for j= k+1:length(lines)
           if ~(m_p(k,j,1)==-1 && m_p(k,j,2)==-1)
               dis=sqrt((m_p(k:end,j:end,1)-m_p(k,j,1)).^2+(m_p(k:end,j:end,2)-m_p(k,j,2)).^2);
               dis(1,1)=100;
               min_val=min(dis(:));
               [k1, j1]=find(dis==min_val);
%                m_p(k1,j1,1)=0;
%                m_p(k1,j1,2)=0;
               if(min_val<10 && abs(lines(k).theta-lines(j).theta)<5)
                  %plot(m_p(k,j,1),m_p(k,j,2),'x','LineWidth',2,'Color','white');
                  mid_rect=[mid_rect;m_p(k,j,1) m_p(k,j,2)];
               end
           end
       end
   end
end
toc;
figure;
imshow(frame_region);hold on;
plot(mid_rect(:,1),mid_rect(:,2),'x','LineWidth',2,'Color','white');
figure;
imshowpair(edge_im,frame_region,'montage');

%%
% If = imfill(edge_im, 'holes');
% figure;
% imshowpair(edge_im,If,'montage');