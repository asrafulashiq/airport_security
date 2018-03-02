% ---------------------------------
%          BBS demo script
% ---------------------------------
close all; clear; clc;
%% set BBS params
gamma = 2; % weighing coefficient between Dxy and Drgb
pz = 3; % non-overlapping patch size used for pixel descirption
dataDir ='..\data';

%% load images and target location
[I,Iref,T,rect,rectGT] = loadImageAndTemplate(1,dataDir);

%% adjust image and template size so they are divisible by the patch size 'pz'
[I,T,rect,Iref] = adjustImageSize(I,T,rect,Iref,pz);
szT = size(T);  szI = size(I);

%% run BBS
tic;
BBS = computeBBS(I,T,gamma, pz);
% interpolate likelihood map back to image size 
BBS = BBinterp(BBS, szT(1:2), pz, NaN);
t = toc;
fprintf('BBS computed in %.2f sec (|I| = %dx%d , |T| = %dx%d)\n',t,szI(1:2),szT(1:2));

%% find target position in image (max BBS)
[rectOut] = findTargetLocation(BBS,'max',rect(3:4));

%% compute overlap with ground-truth
ol = rectOverlap(rectCorners(rectGT),rectCorners(rectOut));

%% plot results
figure(1);clf;
subplot(2,2,1);imshow(Iref) ;
rectangle('position',rect   ,'linewidth',2,'edgecolor',[0,1,0]);colorbar;title('Reference image');
subplot(2,2,2);imshow(I)    ;hold on;
rct(1) = rectangle('position',rectGT,'linewidth',2,'edgecolor',[0,1,0]);
plt(1) = plot(nan,nan,'s','markeredgecolor',get(rct(1),'edgecolor'),'markerfacecolor',get(rct(1),'edgecolor'),'linewidth',3); leg{1} = 'GT';
rct(2) = rectangle('position',rectOut,'linewidth',2,'edgecolor',[1,0,0]);
plt(2) = plot(nan,nan,'s','markeredgecolor',get(rct(2),'edgecolor'),'markerfacecolor',get(rct(2),'edgecolor'),'linewidth',3); leg{2} = 'BBS';
legend(plt,leg,'location','southeast');set(gca,'fontsize',12);
colorbar;title({'Query image',sprintf('Overlap = %.2f',ol)});
subplot(2,2,3);imagesc(BBS) ;rectangle('position',rectOut,'linewidth',2,'edgecolor',[1,0,0]);colormap jet;axis image;colorbar;title('BBS score');

