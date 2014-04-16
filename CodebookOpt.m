function [ B ] = CodebookOpt( B_init, X, lambda,sigma)
% Performs incremental codebook optimization using algorithm 4.1
%
% Inputs:
% B_init: initial codebook M entries, D long
% X: array of samples N entries, D long
% lambda: constant (500 in LLC paper)
% sigma: constant (100 in LLC paper)
%
% Output:
% B: optimized codebook
%

B = B_init;
[M D1] = size(B);
[N D2] = size(X);

for i = 1 : N
    
    d = zeros(1, M);
    
    for j = 1 : M
        d(1, j) = exp(norm(X(i, :) - B(j, :))^2/sigma);
    end
    
    %normalize d
    d = (d - min(d)) / ( max(d) - min(d) );
    
    
    
    %coding
    one = ones(1, D1);
    
    % compute data covariance matrix
    B_1x = B - one *X(i, :)';
    
    C = B_1x * B_1x' + lambda *diag(d);
    
    % reconstruct LLC code
    c_i = C \ ones(size(C,1), 1);
    c_i = c_i /(ones(1, size(C,1))*c_i);
    
    
    %thresholding
    id = find(abs(c_i) > .01);
    
    B_i = B(id,:);
    
    B_2x = B_i - one *X(i, :)';
    C = B_2x * B_2x';
    
    % reconstruct LLC code
    c_i_hat = C \ ones(size(C,1));
    c_i_hat = c_i_hat /sum(c_i_hat);
    
    
    %update basis
    delta_B_i = -2 .* c_i_hat * (X(i, :) -  c_i_hat' *B_i);
    
    m = sqrt(1/i);
    
    B_i = B_i - m .* delta_B_i/norm(c_i_hat);
    
    B_i = B_i./norm(B_i);
    
    
    B(id,:) = B_i;
    
end



end

