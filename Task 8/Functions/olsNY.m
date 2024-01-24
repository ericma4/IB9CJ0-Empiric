function [beta,t_out,se_out,pval_out,resid,yhat,R2,R2adj,bic,aic] = olsNY(y,X,L,H,type)
     
% PURPOSE: computes OLS with Robust, Newey-West, and Hansen-Hodrick adjusted
%           heteroscedastic-serial consistent standard errors

% u is residual
% Inputs:
%  y = T x 1 vector, left hand variable data
%  X = T x n matrix, right hand variable data
%  L = number of lags to include in NW corrected standard errors
%  H = number of lags to include in HH corrected standard errors
%
%Note: you must make one column of X a vector of ones if you want a
%   constant.
% Output:
%  beta = regression coefficients 1 x n vector of coefficients
%  R2    =    unadjusted
%  R2adj = adjusted R2
%  X2(Degrees of Freedom) = : Chi-squared statistic for all coefficients
%                               jointly zero.
%  std  = corrected standard errors.
%  t_   = t-stat for NW and HH
%Note: For chi-square test program checks whether first is a constant and ignores that one for
%       test. If there is only one beta the program does not report X^2
%       results since t_stat^2= X2.
%Note: program automatically displays outputs in an organized format. If you want
%to disable the automatic display just comment lines 129-136.

%Estimate Betas and Residuals
[T,n]   =   size(X);
beta    =   (X'*X)\(X'*y);
%beta    =   pinv(X'*X)*(X'*y);
resid       =   y-X*beta;
yhat = X*beta;
u = resid*ones(1,n);
err = X.*u; %estimating residuals for each beta
y_bar = mean(y);

R2 = 1-resid'*resid/(y'*y-T*(y_bar^2));
R2adj = 1-((1-R2)*(T-1))/(T-n);

%F_ols = (R2/(n-1))/((1-R2)/(T-n));
bic = log(resid'*resid/T)+n*log(T)/T;
aic = log(resid'*resid/T)+2*n/T;

if strcmp(type,'HH') 
%Calculate Hansen Hodrick Corrected Standard Errors
V=[err'*err]/T; %regular weighting matrix
if H > -1
    for ind_i = (1:H)
        S = err(1:T-ind_i,:)'*err(1+ind_i:T,:)/T;
        V = V + (1-1*ind_i/(H+1))*(S + S');
    end
end
D       =   inv((X'*X)/T);
varb = 1/T*D*V*D;
elseif strcmp(type,'NW') 
%-----------------------------------------------------------------------%
%Calculate NW Corrected Standard Errors

Q = 0;
for l = 0:L
w_l = 1-l/(L+1);
for t = l+1:T
  if (l==0)   % This calculates the S_0 portion
    Q = Q  + resid(t) ^2 * X(t, :)' * X(t,:);
  else        % This calculates the off-diagonal terms
    Q = Q + w_l * resid(t) * resid(t-l)* ...
      (X(t, :)' * X(t-l,:) + X(t-l, :)' * X(t,:));
  end
end
end
  
Q = 1/(T-n) * Q;
  % Calculate Newey-White standard errors
varb = T * inv(X' * X) * Q * inv(X' * X);


elseif strcmp(type,'robust') 
%-----------------------------------------------------------------------%
%Calculate Robust Standard Errors
V=[err'*err]/T;
D       =   inv((X'*X)/T);
varb = 1/T*D*V*D; % Greene P.313, equation (9-27)
%-----------------------------------------------------------------------%
%Calculate the basic OLS standard error
else
S_squared = resid'*resid / (T-n);    
V = S_squared * (X'*X)/T;
D       =   inv((X'*X)/T);
varb = 1/T*D*V*D; % Greene P.313, equation (9-27)
end

se_out = sqrt(diag(varb));
t_out = beta./se_out;   
pval_out = 2*(1-tcdf(abs(t_out),T-n));


end
