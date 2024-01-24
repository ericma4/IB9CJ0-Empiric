%
%   	premia.m
% This Matlab code computes the maximum correlation risk premia and the associated t-statistics.
%
% Input:
% F: K systematic factors
% R: N test assets
% lag: Number of lags of Newey-West adjustment (default is 0)
%      For automatic lag selection, set lag to be an empty matrix.
%
% Output:
% est  : mimicking portfolio risk premia estimates
% tstat: t-statistics of mimicking portfolio risk premia estimates 
%

function alpha = alphastar(F,R,MKTB,lag)     
if nargin<4
   lag = 0;
end
index = any(isnan(F),2);
F(index,:) = [];
[T,K] = size(F);
muR = mean(R)';
muF = mean(F)';
VR = cov(R,1);
Rd = (R-ones(T,1)*muR');
VRF = Rd'*F./T;
A = inv(VR)*VRF;
fstar = R*A;
X  = [ones(length(MKTB), 1) MKTB];
b = inv(X'*X)*X'*fstar;
alpha = b(1);
