function [ H_all ] = BuildHistograms2( imageFileList, dataBaseDir, featureSuffix, dictionarySize, canSkip, K )
%function [ H_all ] = BuildHistograms2( imageFileList, dataBaseDir, featureSuffix, dictionarySize, canSkip )
%
%find texton labels of patches and compute texton histograms of all images
%   
% For each image the set of sift descriptors is loaded and then each
%  descriptor is labeled with its texton label. Then the global histogram
%  is calculated for the image. If you wish to just use the Bag of Features
%  image descriptor you can stop at this step, H_all is the histogram or
%  Bag of Features descriptor for all input images.
%
% imageFileList: cell of file paths
% imageBaseDir: the base directory for the image files
% dataBaseDir: the base directory for the data files that are generated
%  by the algorithm. If this dir is the same as imageBaseDir the files
%  will be generated in the same location as the image file
% featureSuffix: this is the suffix appended to the image file name to
%  denote the data file that contains the feature textons and coordinates. 
%  Its default value is '_sift.mat'.
% dictionarySize: size of descriptor dictionary (200 has been found to be
%  a good size)
% canSkip: if true the calculation will be skipped if the appropriate data 
%  file is found in dataBaseDir. This is very useful if you just want to
%  update some of the data or if you've added new images.
% K: Number of nearest neighbors to use when calculating LLC

fprintf('Building Histograms\n\n');

%% parameters

if(nargin<3)
    dictionarySize = 200
end

if(nargin<4)
    canSkip = 0
end

if(nargin<5)
    K = 5
end

%% load texton dictionary (all texton centers)

inFName = fullfile(dataBaseDir, sprintf('dictionary_%d.mat', dictionarySize));
load(inFName,'dictionary');

%% compute texton labels of patches and whole-image histograms
H_all = [];

for f = 1:size(imageFileList,1)

    imageFName = imageFileList{f};
    [dirN base] = fileparts(imageFName);
    baseFName = fullfile(dirN, base);
    inFName = fullfile(dataBaseDir, sprintf('%s%s', baseFName, featureSuffix));
    
    outFName = fullfile(dataBaseDir, sprintf('%s_texton_ind_%d.mat', baseFName, dictionarySize));
    outFName2 = fullfile(dataBaseDir, sprintf('%s_hist_%d.mat', baseFName, dictionarySize));
    if(size(dir(outFName),1)~=0 && size(dir(outFName2),1)~=0 && canSkip)
        load(outFName2, 'H');
        H_all = [H_all; H];
        continue;
    end
    
    %% load sift descriptors
    load(inFName, 'features');
    ndata = size(features.data,1);
    %ddata = size(features.data,2);
    ddata = size(dictionary,1);

    %% find texton indices and compute histogram 
    texton_ind.data = zeros(ndata,ddata);
    texton_ind.x = features.x;
    texton_ind.y = features.y;
    texton_ind.wid = features.wid;
    texton_ind.hgt = features.hgt;
    %run in batches to keep the memory foot print small
    batchSize = 500;
    if ndata <= batchSize
        texton_ind.data = CalculateLLC(features.data, dictionary, K);
    else
        for j = 1:batchSize:ndata
            lo = j;
            hi = min(j+batchSize-1,ndata);
            texton_ind.data(lo:hi,:) = CalculateLLC(features.data(lo:hi,:), dictionary, K);
        end
    end

    H = hist(texton_ind.data, 1:dictionarySize);

    %% save texton indices and histograms
    save(outFName, 'texton_ind');
    save(outFName2, 'H');
end

%% save histograms of all images in this directory in a single file
outFName = fullfile(dataBaseDir, sprintf('histograms_%d.mat', dictionarySize));


end

function C = CalculateLLC(X,B,K)
    % INPUT:
    % - X: The features that were extracted. A NxD matrix, where N is 
    %      the number of features and D is the dimension of the features
    % - B: The codebook. A MxD matrix, where D is the dimension of the
    %      codewords, and M is the number of entries in the codebook
    % - K: The number of nearest neighbors to use as a bases for fast encoding
    % OUTPUT:
    % - C: A MxN matrix of coded features

    %Find the K-nearest neighbors of B to X
    [knn_idx,knn_D] = knnsearch(B,X,'K',K);

    %Solve the optimization problem for each feature (Eq 7 in the paper)
    D = size(X,2);
    if D ~= size(B,2)
      error('X and B must have the same number of rows\n')
    end
    N = size(X,1);
    M = size(B,1);
    C = zeros(N,M);
    for i=1:N
      Bi = B(knn_idx(i,:),:); %knn bases: A KxD matrix
      %Minimizing the constrained least squares problem with respect to ci:
      ci_bar = (Bi - repmat(X(i,:),K,1))*(Bi - repmat(X(i,:),K,1))' \ ones(K,1);
      ci = ci_bar / (ones(1,K)*ci_bar);

      C(i,knn_idx(i,:)) = ci';
    end
end
