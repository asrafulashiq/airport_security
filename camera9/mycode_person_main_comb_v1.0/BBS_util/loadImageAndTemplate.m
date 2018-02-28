function [I,Iref,T,rect,gtRect] = loadImageAndTemplate(pairN,dataDir)

imFiles = dir(sprintf('%s\\pair%04d*.jpg',dataDir,pairN));
rectFile = dir(sprintf('%s\\pair%04d*.txt',dataDir,pairN));

Iref    = im2double(imread(fullfile(dataDir,imFiles(1).name)));
I       = im2double(imread(fullfile(dataDir,imFiles(2).name)));
rect    = round(load(fullfile(dataDir,rectFile(1).name)));
gtRect  = round(load(fullfile(dataDir,rectFile(2).name)));
T = imcrop(Iref,rect);


