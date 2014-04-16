function [label, centroid, dis] = FastKMean(X, k, options)
% FKMEANS Fast K-means with optional weighting and careful initialization.
% [L, C, D] = FKMEANS(X, k) partitions the vectors in the n-by-p matrix X
% into k (or, rarely, fewer) clusters by applying the well known batch
% K-means algorithm. Rows of X correspond to points, columns correspond to
% variables. The output k-by-p matrix C contains the cluster centroids. The
% n-element output column vector L contains the cluster label of each
% point. The k-element output column vector D contains the residual cluster
% distortions as measured by total squared distance of cluster members from
% the centroid.
%
% FKMEANS(X, C0) where C0 is a k-by-p matrix uses the rows of C0 as the
% initial centroids instead of choosing them randomly from X.
%
% FKMEANS(X, k, options) allows optional parameter name/value pairs to 
% be specified. Parameters are:
%
%   'weight' - n-by-1 weight vector used to adjust centroid and distortion
%              calculations. Weights should be positive.
%   'careful' - binary option that determines whether "careful seeding"
%               as recommended by Arthur and Vassilvitskii is used when
%               choosing initial centroids. This option should be used
%               with care because numerical experiments suggest it may
%               be counter-productive when the data is noisy.

n = size(X,1);

% option defaults
weight = 0; % uniform unit weighting
careful = 0;% random initialization

if nargin == 3
    if isfield(options, 'weight')
        weight = options.weight;
    end
    if isfield(options,'careful')
        careful = options.careful;
    end
end

% If initial centroids not supplied, choose them
if isscalar(k)
    % centroids not specified
    if careful
        k = spreadseeds(X, k);
    else
        k = X(randsample(size(X,1),k),:);
    end
end

% generate initial labeling of points
[~,label] = max(bsxfun(@minus,k*X',0.5*sum(k.^2,2)));
k = size(k,1);

last = 0;

if ~weight
    % code defactoring for speed
    while any(label ~= last)
        % remove empty clusters
        [~,~,label] = unique(label);
        % transform label into indicator matrix
        ind = sparse(label,1:n,1,k,n,n);
        % compute centroid of each cluster
        centroid = (spdiags(1./sum(ind,2),0,k,k)*ind)*X;
        % compute distance of every point to each centroid
        distances = bsxfun(@minus,centroid*X',0.5*sum(centroid.^2,2));
        % assign points to their nearest centroid
        last = label;
        [~,label] = max(distances);
        label= label';
    end
    dis = ind*(sum(X.^2,2) - 2*max(distances)');
else
    while any(label ~= last)
        % remove empty clusters
        [~,~,label] = unique(label);
        % transform label into indicator matrix
        ind = sparse(label,1:n,weight,k,n,n);
        % compute centroid of each cluster
        centroid = (spdiags(1./sum(ind,2),0,k,k)*ind)*X;
        % compute distance of every point to each centroid
        distances = bsxfun(@minus,centroid*X',0.5*sum(centroid.^2,2));
        % assign points to their nearest centroid
        last = label;
        [~,label] = max(distances);
    end
    dis = ind*(sum(X.^2,2) - 2*max(distances)');
end
label = label';

function D = sqrdistance(A, B)
n1 = size(A,1); n2 = size(B,2);
m = (sum(A,1)+sum(B,1))/(n1+n2);
A = bsxfun(@minus,A,m);
B = bsxfun(@minus,B,m);
D = full((-2)*(A*B'));
D = bsxfun(@plus,D,full(sum(B.^2,2))');
D = bsxfun(@plus,D,full(sum(A.^2,2)))';
end

function [S, idx] = spreadseeds(X, k)
[n,d] = size(X);
idx = zeros(k,1);
S = zeros(k,d);
D = inf(n,1);
idx(1) = ceil(n.*rand);
S(1,:) = X(idx(1),:);
for i = 2:k
    D = min(D,sqrdistance(S(i-1,:),X));
    idx(i) = find(cumsum(D)/sum(D)>rand,1);
    S(i,:) = X(idx(i),:);
end
end

end
