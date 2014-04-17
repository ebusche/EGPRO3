function [ output_args ] = SVMclass(file, classification, trainingNum)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%use .Mat file to create a text file of the right format
load(file);

[images features] = size(pyramid_all);


%write to file in right format
fileID = fopen('exp.txt','w');
for i = 1 : images
    classNum = classification(i);
    fprintf(fileID,'%d', classNum);
    for j = 1 : features
        fprintf(fileID,' %d:%9.8f', j ,pyramid_all(i,j));
        
    end
    fprintf(fileID,'\n');
end
fclose(fileID);



% addpath to the liblinear toolbox
addpath('./libsvm-3.18/matlab');

% addpath to the data
dirData = './libsvm-3.18';
addpath(dirData);

% read the data set
[cat_label, cat_inst] = libsvmread(fullfile('exp.txt'));
[N D] = size(cat_inst);

%scale the data 
cat_inst = (cat_inst - repmat(min(cat_inst,[],1),size(cat_inst,1),1))*spdiags(1./(max(cat_inst,[],1)-min(cat_inst,[],1))',0,size(cat_inst,2),size(cat_inst,2));

% Determine the train and test index
trainIndex = zeros(N,1); trainIndex(1:trainingNum) = 1;
testIndex = zeros(N,1); testIndex(trainingNum+1:N) = 1;
trainData = cat_inst(trainIndex==1,:);
trainLabel = cat_label(trainIndex==1,:);
testData = cat_inst(testIndex==1,:);
testLabel = cat_label(testIndex==1,:);


% Train the SVM
m = libsvmtrain(trainLabel, trainData, '-t 0');
% Use the SVM model to classify the data
[predict_label, accuracy, prob_values] = libsvmpredict(testLabel, testData, m); % run the SVM model on the test data

[C,order] = confusionmat(testLabel, predict_label);
C

end

