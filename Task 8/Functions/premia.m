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

function [mustar,tstat,SD,Sh2adj,pval] = premia(F,R,lag)     
if nargin<3
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
SD = std(fstar);
mustar = mean(fstar)';
Vstar = cov(fstar,1);
Sh2 = mustar'*inv(Vstar)*mustar;
Fd = (F-ones(T,1)*muF');
vt = Rd*inv(VR)*muR;
epst = Fd-Rd*A;
qt = (fstar-ones(T,1)*mustar')+epst.*(vt*ones(1,K));
%
%   t-stat of estimates.
%
vn = nw(qt,lag);
se = sqrt(vn/T);
tstat = mustar./se;

SR1a = zeros(T,1);
   for t=1:T 
       R1 = R;
       F1 = F;
       R1(t,:) = [];
       F1(t,:) = [];
       muR = mean(R1)';
       Rd = R1-ones(T-1,1)*muR';
       VRf = Rd'*F1./(T-1);
       VR = cov(R1,1);
       A = inv(VR)*VRf;
       fstar1 = R1*A;
       mustar1 = mean(fstar1)';
       Vstar1 = cov(fstar1,1);
       SR1a(t) = mustar1'*inv(Vstar1)*mustar1;
   end
   Sh2adj = T*Sh2-(T-1)*mean(SR1a);
   pval = 1-chi2cdf(T*Sh2,K);


