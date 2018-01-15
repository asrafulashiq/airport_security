%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% data loading %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% folder name and mat files
im_folder = 'data_people';
mat_file = 'trainingdata_people.mat';
load(mat_file); % get only ids
mat_file = 'trainingdata_people_6A.mat';
load(mat_file);
ids = ids(1:numel(imageFilenames));

%% get deep features
net = vgg19();
layers = [ 28, 19];
sz_window = net.Layers(1).InputSize(1:2);

%% image ids

shuffle = true;

id1 = 1;
id2 = 2;

% get all filenames of id1 & 2
files_of_id1 = imageFilenames([ids{:}]==id1);
files_of_id2 = imageFilenames([ids{:}]==id2);

bbs1 = BoundingBox([ids{:}]==id1);
bbs2 = BoundingBox([ids{:}]==id2);

if shuffle
    files_of_id1 = files_of_id1(randperm(numel(files_of_id1)));
    files_of_id2 = files_of_id1(randperm(numel(files_of_id2)));    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% compare images %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% compare same id
size_wz = [224 224];

%% id 1

err_1 = []; % error for id1
for ii = 1: 100%numel(files_of_id1)-1
    im1 = imresize(imread(files_of_id1{ii}), size_wz);
    im2 = imresize(imread(files_of_id1{ii+1}), size_wz);
    
    im1 = imcrop(im1, bbs1{ii});
    im2 = imcrop(im2, bbs1{ii+1});
    
    % get features
     x1 = getFeat(im1, net, layers);
     x2 = getFeat(im2, net, layers);
     
    % compare features
    err_1(end+1) = compareFeat(x1, x2); 
end

fprintf('ID : 1\n Mean: %.2f\n SD : %.2f\n', mean(err_1), std(err_1));

%% id 2

err_2 = []; % error for id1
for ii = 1: 100%numel(files_of_id1)-1
    im1 = imresize(imread(files_of_id2{ii}), size_wz);
    im2 = imresize(imread(files_of_id2{ii+1}), size_wz);
    
    im1 = imcrop(im1, bbs2{ii});
    im2 = imcrop(im2, bbs2{ii+1});
    
    % get features
     x1 = getFeat(im1, net, layers);
     x2 = getFeat(im2, net, layers);
     
    % compare features
    err_2(end+1) = compareFeat(x1, x2); 
end

fprintf('ID : 2\n Mean: %.2f\n SD : %.2f\n', mean(err_2), std(err_2));

%% id 1 & id 2

err_12 = []; % error for id1
for ii = 1: 100%numel(files_of_id1)-1
    im1 = imresize(imread(files_of_id1{ii}), size_wz);
    im2 = imresize(imread(files_of_id2{ii}), size_wz);
    
    im1 = imcrop(im1, bbs1{ii});
    im2 = imcrop(im2, bbs2{ii});
    
    % get features
     x1 = getFeat(im1, net, layers);
     x2 = getFeat(im2, net, layers);
     
    % compare features
    err_12(end+1) = compareFeat(x1, x2); 
end

fprintf('ID : 1 & 2\n Mean: %.2f\n SD : %.2f\n', mean(err_12), std(err_12));

%%
% i_1 = '525';
% i_2 = '560';%'1184';
% 
% im_1 = dir(fullfile(im_folder, [i_1 '_*.jpg']));
% im_2 = dir(fullfile(im_folder, [i_2 '_*.jpg']));
% 
% im_full_1 = imread(fullfile(im_folder, im_1.name));
% im_full_2 = imread(fullfile(im_folder, im_2.name));
% 
% b1 = BoundingBox{str2num(i_1)};
% b2 = BoundingBox{str2num(i_2)};
% 
% im1 = imcrop(im_full_1, b1);
% im2 = imcrop(im_full_2, b2);
% 
% figure(1); imshow(im1);
% figure(2); imshow(im2);
% 
% x1 = getFeat(im1, net, layers);
% x2 = getFeat(im2, net, layers);
% 
% compareFeat(x1(1), x2(1))

%% extract features
function feat = getFeat(img, net, layers)
img = imresize(img, [224 224]);
feat = cell(length(layers), 1);
for ii = 1:length(layers)
    x = activations(net, img, layers(ii));
    %x = imresize(x, sz_window);
    feat{ii}=x;
end
end

function err = compareFeat(x1, x2)
    err = [];
    for i = 1:numel(x1)
       err(i) = xcorr(x1{i}, x2{i}, 0, 'coeff'); 
    end
    err = mean(err);
end

%function feat = getHOGFeat(img)





