% ------------------------------------------------------------------------------------------
%       Run BBS for template matching on the dataset used in the CVPR 2015 publication
%       Best Buddies Similarity for Robust Template Matching
%       Tali Dekel, Shaul Oron, Shai Avidan, Michael Rubinstein, William T. Freeman
% ------------------------------------------------------------------------------------------
close all; clear; clc;
warning('off');
%% set BBS params
gamma = 2; % weighing coefficient between Dxy and Drgb
pz = 3; % non-overlapping patch size used for pixel descirption
verbose = 1;
overwrite = 0 ;
dataDir ='..\data';
resDir = '..\results';
resFile = fullfile(resDir,'BBS_CVPR_2015.mat');
if ~exist(resDir,'dir'),mkdir(resDir);end
nPairs = 105;
ol = nan(nPairs,1);
if ~overwrite && exist(resFile,'file')
    %load existing results if found     
    load(resFile);    
end
%% compute BBS for all image-pairs in dataset
p0 = find(isnan(ol),1,'first');
for p = p0:nPairs
    % load images and target location
    [I,Iref,T,rect,rectGT] = loadImageAndTemplate(p,dataDir);
    % adjust image and template size so they are divisible by the patch size 'pz'
    [I,T,rect,Iref] = adjustImageSize(I,T,rect,Iref,pz);
    szT = size(T);  szI = size(I);
    % run BBS
    tic;
    BBS = computeBBS(I,T,gamma,pz);
    % interpolate likelihood map back to image size
    BBS = BBinterp(BBS, szT(1:2), pz, NaN);
    t = toc;
    % find target position in query image (max BBS)
    [rectOut] = findTargetLocation(BBS,'max',rect(3:4));
    % compute overlap with ground-truth
    ol(p) = rectOverlap(rectCorners(rectGT),rectCorners(rectOut));
    save(resFile,'ol')
    if verbose
        % plot results
        fprintf('Pair %03d: BBS computed in %.2f sec (|I| = %dx%d , |T| = %dx%d)\n',p,t,szI(1:2),szT(1:2));
        figure(1);clf;
        subplot(2,2,1);imshow(Iref) ;
        rectangle('position',rect   ,'linewidth',2,'edgecolor',[0,1,0]);colorbar;title(sprintf('Pair %03d\nReference image',p));
        subplot(2,2,2);imshow(I)    ;hold on;
        rct(1) = rectangle('position',rectGT,'linewidth',2,'edgecolor',[0,1,0]);
        plt(1) = plot(nan,nan,'s','markeredgecolor',get(rct(1),'edgecolor'),'markerfacecolor',get(rct(1),'edgecolor'),'linewidth',3); leg{1} = 'GT';
        rct(2) = rectangle('position',rectOut,'linewidth',2,'edgecolor',[1,0,0]);
        plt(2) = plot(nan,nan,'s','markeredgecolor',get(rct(2),'edgecolor'),'markerfacecolor',get(rct(2),'edgecolor'),'linewidth',3); leg{2} = 'BBS';
        legend(plt,leg,'location','southeast');set(gca,'fontsize',12);
        colorbar;title({'Query image',sprintf('Overlap = %.2f',ol(p))});
        subplot(2,2,3);imagesc(BBS) ;rectangle('position',rectOut,'linewidth',2,'edgecolor',[1,0,0]);colormap jet;axis image;colorbar;title('BBS score');
    end    
end

%% build success curve
th = 0:0.05:1;
for ii = 1:length(th)
    S(ii) = sum(ol>th(ii))/nPairs;
end
figure(2);clf; 
plot(th,S,'linewidth',3); grid on;
xlabel('Threshold');
ylabel('Success rate');
title(sprintf('BBS success curve for CVPR 2015 dataset (AUC = %.3f)',mean(S(1:end-1))));
warning('on');



