%% dataset

location = fullfile('trainingdata.mat');
load(location);
imageFilenames = imageFilenames(:);
BoundingBox = BoundingBox(:);

dataset = table(imageFilenames, BoundingBox);
trainRatio = 0.7;
valRatio = 0.2;
testRatio = 0.1;

[trainInd,valInd,testInd] = dividerand(size(dataset, 1),trainRatio,valRatio,testRatio);


trainingDataset = dataset(trainInd, :);
testDataset = dataset(testInd, :);
validationDataset = dataset(valInd, :);

%% network

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 128, ...
    'LearnRateDropFactor',0.2,...
    'LearnRateDropPeriod',5,...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 5,...
    'Plots','training-progress');

net = alexnet;

%% training

detector = trainFastRCNNObjectDetector(trainingDataset,net,options, ...
    'NegativeOverlapRange', [0 0.4] );

%% test

resultsStruct = struct([]);
for i = 1:2%height(testDataset)
    fprintf('Test %d', i);
    % Read the image.
    I = imread(testDataset.imageFilenames{i});
    
    Ir = imresize(I, [227 227]);
    
    
    % Run the detector.
    [bboxes, scores, labels] = detect(detector, I);
    
    % Collect the results.
    resultsStruct(i).Boxes = bboxes;
    %resultsStruct(i).Scores = scores;
    resultsStruct(i).Labels = labels;
end

% Convert the results into a table.
results = struct2table(resultsStruct);

% Extract expected bounding box locations from test data.
expectedResults = testDataset(:, 2:end);

% Evaluate the object detector using Average Precision metric.
[ap, recall, precision] = evaluateDetectionPrecision(results, expectedResults);


%% accuracy

% Plot precision/recall curve
figure;
plot(recall, precision);
xlabel('Recall');
ylabel('Precision');
grid on;
title(sprintf('Average Precision = %.1f', ap));
