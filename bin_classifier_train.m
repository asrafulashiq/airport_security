%%
clear all;
% bin_size=411;
% lug_size=2310;
% neg_size=1431;
%% load data
path1='./label1_im/';
path2='./label2_im/';
path3='./label3_im/';
data=[];
label=[];
fileFolder=fullfile(path1);
dirOutput=dir(fullfile(fileFolder,'*.jpg'));
fileNames={dirOutput.name}';
h=fspecial('gaussian',[5 5], 0.8);
h2=fspecial('motion',4,-90); 
savepath1='./data/pos1/';
size2=[71 88];
size2=[35 44];
shape1=size2(1)*size2(2);
for i=1:1:size(fileNames,1)
    im1=imresize(imread([path1 fileNames{i,1}]),size2);
    im_g=imfilter(im1,h);
    im_mo=imfilter(im1,h2);
    imr1=imrotate(im1,5,'bilinear','crop');
    imr2=imrotate(im1,-5,'bilinear','crop');
    imr1_resize=imresize(imr1(4:end-4,4:end-4),size2);
    imr2_resize=imresize(imr2(4:end-4,4:end-4),size2);
    imwrite(im1,[savepath1  num2str(5*(i-1)+1) '.jpg']);
    imwrite(im_g,[savepath1  num2str(5*(i-1)+2) '.jpg']);
    imwrite(im_mo,[savepath1  num2str(5*(i-1)+3) '.jpg']);
    imwrite(imr1_resize,[savepath1  num2str(5*(i-1)+4) '.jpg']);
    imwrite(imr2_resize,[savepath1  num2str(5*(i-1)+5) '.jpg']);
%     figure;
%     subplot(3,3,1);
%     imshow(im1);
%     subplot(3,3,2);
%     imshow(im_g);
%     subplot(3,3,3);
%     imshow(im_mo);
%     subplot(3,3,4);
%     imshow(imr1_resize);
%     subplot(3,3,5);
%     imshow(imr2_resize);
    im_vector=[reshape(im1,[shape1,1]) reshape(im_g,[shape1,1]) reshape(im_mo,[shape1,1]) ...
               reshape(imr1_resize,[shape1,1]) reshape(imr2_resize,[shape1,1])];
    data=[data im2double(im_vector)-0.5];
    label=[label [0 0 0 0 0;1 1 1 1 1]];
    i
end
%%
fileFolder=fullfile(path2);
dirOutput=dir(fullfile(fileFolder,'*.jpg'));
fileNames={dirOutput.name}';
savepath2='./data/pos2/';
for i=1:1:size(fileNames,1)
    im1=imresize(imread([path2 fileNames{i,1}]),size2);
    im_g=imfilter(im1,h);
    im_mo=imfilter(im1,h2);
    imr1=imrotate(im1,5,'bilinear','crop');
    imr2=imrotate(im1,-5,'bilinear','crop');
    imr1_resize=imresize(imr1(4:end-4,4:end-4),size2);
    imr2_resize=imresize(imr2(4:end-4,4:end-4),size2);
    imwrite(im1,[savepath2  num2str(5*(i-1)+1) '.jpg']);
    imwrite(im_g,[savepath2  num2str(5*(i-1)+2) '.jpg']);
    imwrite(im_mo,[savepath2  num2str(5*(i-1)+3) '.jpg']);
    imwrite(imr1_resize,[savepath2  num2str(5*(i-1)+4) '.jpg']);
    imwrite(imr2_resize,[savepath2  num2str(5*(i-1)+5) '.jpg']);
%     figure;
%     subplot(3,3,1);
%     imshow(im1);
%     subplot(3,3,2);
%     imshow(im_g);
%     subplot(3,3,3);
%     imshow(im_mo);
%     subplot(3,3,4);
%     imshow(imr1_resize);
%     subplot(3,3,5);
%     imshow(imr2_resize);
    im_vector=[reshape(im1,[shape1,1]) reshape(im_g,[shape1,1]) reshape(im_mo,[shape1,1]) ...
               reshape(imr1_resize,[shape1,1]) reshape(imr2_resize,[shape1,1])];
    data=[data im2double(im_vector)-0.5];
    label=[label [0 0 0 0 0;1 1 1 1 1]];
    i
end
%%
fileFolder=fullfile(path3);
dirOutput=dir(fullfile(fileFolder,'*.jpg'));
fileNames={dirOutput.name}';
savepath3='./data/neg/';
for i=1:1:size(fileNames,1)
    im1=imresize(imread([path3 fileNames{i,1}]),size2);
    im_g=imfilter(im1,h);
    im_mo=imfilter(im1,h2);
    imr1=imrotate(im1,5,'bilinear','crop');
    imr2=imrotate(im1,-5,'bilinear','crop');
    imr1_resize=imresize(imr1(4:end-4,4:end-4),size2);
    imr2_resize=imresize(imr2(4:end-4,4:end-4),size2);
    imwrite(im1,[savepath3  num2str(5*(i-1)+1) '.jpg']);
    imwrite(im_g,[savepath3  num2str(5*(i-1)+2) '.jpg']);
    imwrite(im_mo,[savepath3  num2str(5*(i-1)+3) '.jpg']);
    imwrite(imr1_resize,[savepath3  num2str(5*(i-1)+4) '.jpg']);
    imwrite(imr2_resize,[savepath3  num2str(5*(i-1)+5) '.jpg']);
%     figure;
%     subplot(3,3,1);
%     imshow(im1);
%     subplot(3,3,2);
%     imshow(im_g);
%     subplot(3,3,3);
%     imshow(im_mo);
%     subplot(3,3,4);
%     imshow(imr1_resize);
%     subplot(3,3,5);
%     imshow(imr2_resize);
    im_vector=[reshape(im1,[shape1,1]) reshape(im_g,[shape1,1]) reshape(im_mo,[shape1,1]) ...
               reshape(imr1_resize,[shape1,1]) reshape(imr2_resize,[shape1,1])];
    data=[data im2double(im_vector)-0.5];
    label=[label [1 1 1 1 1;0 0 0 0 0]];
    i
end
%% 
inputs = data;
targets = label;

% Create a Pattern Recognition Network
hiddenLayerSize = 512;
net = patternnet(hiddenLayerSize);


% Set up Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;


% Train the Network
[net,tr] = train(net,inputs,targets);

% Test the Network
outputs = net(inputs);
errors = gsubtract(targets,outputs);
performance = perform(net,targets,outputs)

% View the Network
view(net)

% Plots
% Uncomment these lines to enable various plots.
% figure, plotperform(tr)
% figure, plottrainstate(tr)
% figure, plotconfusion(targets,outputs)
% figure, ploterrhist(errors)
%%
outputs = net(inputs);
res=zeros(1,size(targets,2));
res(1,targets(:,1)==1 & outputs(:,1)>outputs(:,2))=1;
res(1,targets(:,2)==1 & outputs(:,1)<=outputs(:,2))=1;
a=[];
for i=1:size(res,2)
    if res(1,i)==1
        a=[a i];
    end
end