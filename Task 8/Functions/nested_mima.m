%
%   nested_mima.m
%   This MATLAB M-file computes the difference of adjusted squared
%   Sharpe ratios of two nested models with mimicking portfolios as well 
%   as its p-value 
%
% Input:
% BigF: set of all factors
% R: set of returns (possibly including the traded factors)
% m1: index for model 1
% m2: index for model 2
% m1t: an indicator of whether model 1 is a traded factor model or not
% m2t: an indicator of whether model 2 is a traded factor model or not
% lag: number of lags of Newey-West adjustment 
% Output:
% dtheta2: difference of bias-adjusted sample squared Sharpe ratios of models 1 and 2
% pval: p-value of testing H_0: theta_A^2=theta_B^2
%
function [dtheta2,pval] = nested_mima(BigF,R,m1,m2,m1t,m2t,lag)
if nargin<7
   lag = 0;
   if nargin<6
      m2t = 0;
      if nargin<5
         m1t = 0;
      end
   end   
end
if m1t&&m2t
   [dtheta2,~,pval] = nested(BigF,m1,m2);
   return
end
if length(m1)<length(m2)
   F1 = BigF(:,m1);
   F2 = BigF(:,setdiff(m2,m1));
else
   F1 = BigF(:,m2);
   F2 = BigF(:,setdiff(m1,m2));
end
index = any(isnan([F1 F2]),2);
F1(index,:) = [];
F2(index,:) = [];
K1 = size(F1,2);
K2 = size(F2,2);
F = [F1 F2];
T = size(F,1);  %
muR = mean(R)';
muF = mean(F)';
Fd = F-ones(T,1)*muF';
F1d = Fd(:,1:K1);
Rd = R-ones(T,1)*muR';
VRf = Rd'*F./T;
VR = cov(R,1);
A = inv(VR)*VRf;
epst = Fd-Rd*A;
epst1 = epst(:,1:K1);
epst2 = epst(:,K1+1:end);
fstar = R*A;
f1star = fstar(:,1:K1);
f2star = fstar(:,K1+1:end);
mu1star = mean(f1star)';
mu2star = mean(f2star)';
F1dstar = (f1star-ones(T,1)*mu1star');
F2dstar = (f2star-ones(T,1)*mu2star');
Vstar = cov(fstar,1);
V11star = Vstar(1:K1,1:K1);
V12star = Vstar(1:K1,K1+1:end);
V21star = V12star';
V22star = Vstar(K1+1:end,K1+1:end);
wt = epst2-epst1*inv(V11star)*V12star;
vt = Rd*inv(VR)*muR;
etat = F2dstar-F1dstar*inv(V11star)*V12star;
y1t = 1-F1d*inv(V11star)*mu1star;
u1t = F1dstar*inv(V11star)*mu1star;
qt = etat.*(y1t*ones(1,K2))+wt.*((vt-u1t)*ones(1,K2));
vq = nw(qt,lag);

alpha21star = mu2star-V21star*inv(V11star)*mu1star; %
wald = T*alpha21star'*inv(vq)*alpha21star; %
pval = 1-chi2cdf(wald,K2); %
mustar = [mu1star; mu2star]; %
SR1 = mu1star'*inv(V11star)*mu1star;
SR2 = mustar'*inv(Vstar)*mustar;
if m1t
   SR1 = (T-K1-2)/T*SR1-K1/T;
end
if m2t
   SR2 = (T-K1-K2-2)/T*SR2-(K1+K2)/T;
else
   SR1a = zeros(T,1);
   SR2a = zeros(T,1);
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
       fstar = R1*A;
       mustar = mean(fstar)';
       Vstar = cov(fstar,1);
       mu1star = mustar(1:K1);
       V11star = Vstar(1:K1,1:K1);
       if ~m1t
          SR1a(t) = mu1star'*inv(V11star)*mu1star;
       end
       if ~m2t
          SR2a(t) = mustar'*inv(Vstar)*mustar;
       end
   end
   if ~m1t
      SR1 = T*SR1-(T-1)*mean(SR1a);
   end
   SR2 = T*SR2-(T-1)*mean(SR2a);
end
dtheta2 = SR1-SR2;
if length(m2)>length(m1)
   dtheta2 = dtheta2;
end




