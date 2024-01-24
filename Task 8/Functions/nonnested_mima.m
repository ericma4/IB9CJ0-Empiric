%
%  nonnested_mima.m
%  This MATLAB M-file computes the difference of squared Sharpe ratios
%  of two non-nested models with mimicking portfolios, as well as its p-values under different
%  assumptions on the null hypothesis 
%  Input: 
%  BigF: set of all factors
%  R: test assets (possibly including traded factors)
%  m1: index for model 1
%  m2: index for model 2 
%  m1t: an indicator of whether model 1 is a traded factor model or not
%  m2t: an indicator of whether model 2 is a traded factor model or not
%  lag: Number of lag adjustments for computing Newey-West standard error 
%      (default is lag=0)
%
%  Output:
%  dtheta2: difference of bias-adjusted sample squared Sharpe ratios of models 1 and 2
%  pval1:  p-value of pre-test 
%  pval2a: p-value of normal test not imposing the null
%  pval2b: p-value of normal test imposing the null
%
function [dtheta2,pval1,pval2a,pval2b] = nonnested_mima(BigF,R,m1,m2,m1t,m2t,lag)
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
   [dtheta2,pval1,pval2a,pval2b] = nonnested(BigF,m1,m2,lag);
   return
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
T = length(Y);
K1 = size(F1,2);
K2 = size(F2,2);
K3 = size(F3,2);
FA = [F1 F2];
FB = [F1 F3];
muR = mean(R)';
muFA = mean(FA)';
muFB = mean(FB)';
FAd = (FA-ones(T,1)*muFA');
FBd = (FB-ones(T,1)*muFB');
FA1d = FAd(:,1:K1);
FB1d = FBd(:,1:K1);
Rd = R-ones(T,1)*muR';
VRfA = (R-ones(T,1)*muR')'*FA./T;
VRfB = (R-ones(T,1)*muR')'*FB./T;
VR = cov(R,1);
AA = inv(VR)*VRfA;
AB = inv(VR)*VRfB;
epstA = FAd-Rd*AA;
epstA1 = epstA(:,1:K1);
epstA2 = epstA(:,K1+1:end);
epstB = FBd-Rd*AB;
epstB1 = epstB(:,1:K1);
epstB2 = epstB(:,K1+1:end);
fstarA = R*AA;
mustarA = mean(fstarA)';
fstarB = R*AB;
mustarB = mean(fstarB)';
f1starA = fstarA(:,1:K1);
f2starA = fstarA(:,K1+1:end);
mu1starA = mean(f1starA)';
mu2starA = mean(f2starA)';
f1starB = fstarB(:,1:K1);
f2starB = fstarB(:,K1+1:end);
mu1starB = mean(f1starB)';
mu2starB = mean(f2starB)';
FdstarA = (fstarA-ones(T,1)*mustarA');
F1dstarA = (f1starA-ones(T,1)*mu1starA');
F2dstarA = (f2starA-ones(T,1)*mu2starA');
FdstarB = (fstarB-ones(T,1)*mustarB');
F1dstarB = (f1starB-ones(T,1)*mu1starB');
F2dstarB = (f2starB-ones(T,1)*mu2starB');
VstarA = cov(fstarA,1);
V11starA = VstarA(1:K1,1:K1);
V12starA = VstarA(1:K1,K1+1:end);
V21starA = V12starA';
V22starA = VstarA(K1+1:end,K1+1:end);
VstarB = cov(fstarB,1);
V11starB = VstarB(1:K1,1:K1);
V12starB = VstarB(1:K1,K1+1:end);
V21starB = V12starB';
V22starB = VstarB(K1+1:end,K1+1:end);
wtA = epstA2-epstA1*inv(V11starA)*V12starA;
wtB = epstB2-epstB1*inv(V11starB)*V12starB;
vt = Rd*inv(VR)*muR;
etatA = F2dstarA-F1dstarA*inv(V11starA)*V12starA;
etatB = F2dstarB-F1dstarB*inv(V11starB)*V12starB;
y1tA = 1-FA1d*inv(V11starA)*mu1starA;
y1tB = 1-FB1d*inv(V11starB)*mu1starB;
u1tA = F1dstarA*inv(V11starA)*mu1starA;
u1tB = F1dstarB*inv(V11starB)*mu1starB;
htA = etatA.*(y1tA*ones(1,K2))+wtA.*((vt-u1tA)*ones(1,K2));
htB = etatB.*(y1tB*ones(1,K3))+wtB.*((vt-u1tB)*ones(1,K3));
alpha21star = mu2starA-V21starA*inv(V11starA)*mu1starA; 
alpha31star = mu2starB-V21starB*inv(V11starB)*mu1starB; 
psi = [alpha21star;alpha31star];
ht = [htA htB];
VV = nw(ht,lag);
wald = T*psi'*inv(VV)*psi;
pval1 = 1-chi2cdf(wald,K2+K3);  % pvalue of the pre-test for non-nested models
%%%%%%%%%%%% Normal Test %%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
theta2A = mustarA'*inv(VstarA)*mustarA;
theta2B = mustarB'*inv(VstarB)*mustarB;
uA = FdstarA*inv(VstarA)*mustarA;
uB = FdstarB*inv(VstarB)*mustarB;
yA = 1-epstA*inv(VstarA)*mustarA;
yB = 1-epstB*inv(VstarB)*mustarB;
dt = 2*(uA.*yA-uB.*yB)+(uB.^2-uA.^2)+2*(yB-yA).*vt;
vd = nw(dt,lag);
dt1 = 2*(uA.*yA-uB.*yB)+(uB.^2-uA.^2)+2*(yB-yA).*vt+(theta2A-theta2B);
vd1 = nw(dt1,lag);
SR1 = theta2A;
SR2 = theta2B;
if m1t
   SR1 = (T-K1-K2-2)/T*SR1-(K1+K2)/T;
else
   SR1a = zeros(T,1);
   for t=1:T 
       R1 = R;
       F1 = FA;
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
       SR1a(t) = mustar'*inv(Vstar)*mustar;
   end
   SR1 = T*SR1-(T-1)*mean(SR1a);
end
if m2t
   SR2 = (T-K1-K3-2)/T*SR2-(K1+K3)/T;
else
   SR2a = zeros(T,1);
   for t=1:T 
       R1 = R;
       F1 = FB;
       R1(t,:) = [];
       F1(t,:) = [];
       muR = mean(R1)';
       muF = mean(F1)';
       Rd = R1-ones(T-1,1)*muR';
       VRf = Rd'*F1./(T-1);
       VR = cov(R1,1);
       A = inv(VR)*VRf;
       fstar = R1*A;
       mustar = mean(fstar)';
       Vstar = cov(fstar,1);
       SR2a(t) = mustar'*inv(Vstar)*mustar;
   end
   SR2 = T*SR2-(T-1)*mean(SR2a);
end
dtheta2 = SR1-SR2;
pval2a = 2*(1-normcdf(abs(dtheta2)/sqrt(vd./T)));
pval2b = 2*(1-normcdf(abs(dtheta2)/sqrt(vd1./T)));
