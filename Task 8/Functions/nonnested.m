%
%  nonnested.m
%  This MATLAB M-file computes the difference of squared Sharpe ratios
%  of two non-nested models, as well as its p-values under different
%  assumptions on the null hypothesis 
%  Input: 
%  BigF: set of all factors
%  m1: index for model 1
%  m2: index for model 2 
%  lag: Number of lag adjustments for computing Newey-West standard error 
%      (default is lag=0)
%
%  Output:
%  thetasqd: difference of sample squared Sharpe ratios of models 1 and 2
%  pval1a: p-value of pre-test under conditional homosk
%  pval1b: p-value of pre-test under conditional heterosk
%  pval2a: p-value of normal test not imposing the null
%  pval2b: p-value of normal test imposing the null
%
function [dtheta2,pval1a,pval1b,pval2a,pval2b] = nonnested(BigF,m1,m2,lag)
if nargin<4
   lag = 0;
end
F1 = BigF(:,intersect(m1,m2));
[c,ia,ib] = setxor(m1,m2);
F2 = BigF(:,m1(ia));
F3 = BigF(:,m2(ib));
Y = [F1 F2 F3] ;
index = any(isnan(Y),2);
F1(index,:) = [];
F2(index,:) = [];
F3(index,:) = [];
[~,~,pval1a,pval1b] = grs(F1,[F2 F3]);
T = length(Y);
FA = [F1 F2];
FB = [F1 F3];
KA = size(FA,2);
KB = size(FB,2);
muA = mean(FA)';
muB = mean(FB)';
VA = cov(FA,1);
VB = cov(FB,1);
WA = (T-KA-2)./T*inv(VA);
WB = (T-KB-2)./T*inv(VB);
theta2A=muA'*WA*muA-KA/T;
theta2B=muB'*WB*muB-KB/T;
dtheta2 = theta2A-theta2B;
FAd = FA-ones(T,1)*muA';
FBd = FB-ones(T,1)*muB';
uA = FAd*WA*muA;
uB = FBd*WB*muB;
dt = 2*(uA-uB)-(uA.^2-uB.^2);                    % imposing the null
vd = nw(dt,lag);
dt1 = 2*(uA-uB)-(uA.^2-uB.^2)+(theta2A-theta2B); % not imposing the null
vd1 = nw(dt1,lag);
pval2a = 2*(1-normcdf(abs(dtheta2)/sqrt(vd1./T)));
pval2b = 2*(1-normcdf(abs(dtheta2)/sqrt(vd./T)));






