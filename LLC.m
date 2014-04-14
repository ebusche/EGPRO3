function C = LLC(X,B,K)
% INPUT:
% - X: The features that were extracted. A NxD matrix, where N is 
%      the number of features and D is the dimension of the features
% - B: The codebook. A MxD matrix, where D is the dimension of the
%      codewords, and M is the number of entries in the codebook
% - K: The number of nearest neighbors to use as a bases for fast encoding
% OUTPUT:
% - C: A MxN matrix of coded features
%fprintf('Beginning LLC encoding...\n')

%Find the K-nearest neighbors of B to X
%fprintf('Finding %d nearest neighbors\n',K)
[knn_idx,knn_D] = knnsearch(B,X,'K',K);

%Solve the optimization problem for each feature (Eq 7 in the paper)
D = size(X,2);
if D ~= size(B,2)
  error('X and B must have the same number of rows\n')
end
N = size(X,1);
M = size(B,1);

%fprintf('Calculating C')
C = zeros(N,M);
for i=1:N
  Bi = B(knn_idx(i,:),:); %knn bases: A KxD matrix
  %Minimizing the constrained least squares problem with respect to ci:
  %||xi - Bi*ci||^2 s.t. sum(ci) = 1
  %ci = lsqlin(Bi',X(i,:)',[],[],ones(1,K),1);
  %ci = quadprog(Bi*Bi',X(i,:)*Bi',[],[],ones(1,K),1)
  ci_bar = (Bi - repmat(X(i,:),K,1))*(Bi - repmat(X(i,:),K,1))' \ ones(K,1);
  ci = ci_bar / (ones(1,K)*ci_bar);
  
  C(i,knn_idx(i,:)) = ci';
end

