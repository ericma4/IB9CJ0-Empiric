function Zb = stationaryBB(Z,sim,L)
% PURPOSE: Stationary Block Bootstrap for a vector time series
% ------------------------------------------------------------
% SYNTAX: Zb = stationaryBB(Z,sim,L);
% ------------------------------------------------------------
% OUTPUT: Zb : nxkz resampled time series
% ------------------------------------------------------------
% INPUT:  Z   : nxkz --> vector time series to be resampled
%         sim : 1x1  --> type of bootstrap: 
%                       1 => stationary geometric pdf
%                       2 => stationary uniform pdf
%                       3 => circular (non-random b)
%         L --> block size, depends on sim
%           sim = 1 --> L:1x1 expected block size
%           sim = 2 --> L:2x1 lower and upper limits for uniform pdf
%           sim = 3 --> L:1x1 fixed block size (non-random b)
%        If L=1 and sim=3, the standard iid bootstrap is applied
% ------------------------------------------------------------
% LIBRARY: loopBB [internal]
% ------------------------------------------------------------
% SEE ALSO: overlappingBB, seasBB
% ------------------------------------------------------------
% REFERENCES: Politis, D. and Romano, J. (1994) "The starionary 
% bootstrap", Journal of the American Statistical Association, vol. 89,
% n. 428, p. 1303-1313.
% Politis, D. and White, H (2003) "Automatic block-length
% selection for the dependent bootstrap", Dept. of Mathematics, Univ.
% of California, San Diego, Working Paper.
% ------------------------------------------------------------

% written by:
%  Enrique M. Quilis and Chanik Jo added the optimal expected block size 
%  Macroeconomic Research Department
%  Fiscal Authority for Fiscal Responsibility (AIReF)
%  <enrique.quilis@airef.es>

% Version 2.1 [October 2015]

% Dimension of time series to be bootstrapped
[n,kz] = size(Z);


if L(1) == 0 % if L(1) == 0, only find the optimal expected block size and do nothing else. This is only for the sim = 1 case.

% optimal selection of expected block lengths: This is based on Politis and
% White 2004 to minize the MSE of sample variaince. That is, to reduce both
% bias and inefficiency of sample variance. This opimal selection is also
% based on univariate setting, not multivariate setting. Notwithstanding,
% given the difficulty of selection of the expected block lengths, I used
% this optimal length and use the average of optimal length for each
% variable.

    for j=1:kz 
      opti_size(j) = opti_size_fn(Z(:,j));      
    end

    Zb = opti_size;   

else
    % ------------------------------------------------------------
    %  ALLOCATION
    % ------------------------------------------------------------
    I = zeros(1,n);
    b = zeros(1,n);
    xb = -999.99*ones(n,1);

    % ------------------------------------------------------------
    % INDEX SELECTION
    % ------------------------------------------------------------
    I = round(1+(n-1)*rand(1,n));

    % ------------------------------------------------------------
    % BLOCK SELECTION
    % ------------------------------------------------------------
    switch sim
    case 1 % Stationary BB, geometric pdf
       b = geornd(1/L(1),1,n); 
    % The mean of this distribution is L(1)    
    % generate 1 X n array of probability 1/L(1)
    % We need the number of b, which is the same as the time-series sample size
    % 'n'
    case 2 % Stationary BB, uniform pdf   
       b = round(L(1)+(L(2)-1)*rand(1,n));
    case 3 % Circular bootstrap (fixed block size)
       b = L(1) * ones(1,n);
    end


    % ------------------------------------------------------------
    % WRAPPING THE TIME SERIES AROUND THE CIRCLE
    % ------------------------------------------------------------
    Z = [Z; Z(1:n-1,:)];


    % ------------------------------------------------------------
    % BOOTSTRAP REPLICATION
    % ------------------------------------------------------------
    Zb = [];
    for j=1:kz
       Zb = [Zb loopBB(Z(:,j),n,b,I)];
    end

end

% ============================================================
% loopBB ==> UNIVARIATE BOOTSTRAP LOOP
% ============================================================
function xb = loopBB(x,n,b,I)

h=1;
for m=1:n
   for j=1:b(m)
      xb(h) = x(I(m)+j-1);
      h = h + 1; 
      if (h == n+1); break; end
   end
   if (h == n+1); break; end
end

%b(1) is the block size for re-sampling. If b(1) is greater than n, then
%re-sampling for the first variable is over, and you don't need m = 2.
%since the same matrix b and I are applied for all variables, for the
%re-sampled data, they all have the same time-period. 


xb=xb';



function opti_size = opti_size_fn(X)   

X = rmmissing(X);
N = length(X);
M = N - 1;

G_hat = 0;

for k = -M : M
G_hat = G_hat + lambda_fn(k/M)*abs(k)*R_hat_fn(X,k);
end


f = @(w) (1+cos(w)).*g_hat_fun(X,M,w).^2;
D_hat = 4*g_hat_fun(X,M,0)^2 + 2/pi * quadgk(f,-pi,pi);


opti_size = (2*G_hat^2/D_hat)^(1/3)*N^(1/3);


opti_size;


function g_hat = g_hat_fun(X,M,w)

g_hat = 0;

for k = -M : M
g_hat = g_hat + lambda_fn(k/M)*R_hat_fn(X,k)*cos(w*k);
end

g_hat;



function lambda = lambda_fn(t)

if abs(t) > 0 && abs(t) <= 0.5 
    lambda = 1;    
elseif abs(t) > 0.5 && abs(t) <= 1
    lambda = 2*(1-abs(t));        
else
    lambda = 0;
end

lambda;


function R_hat = R_hat_fn(X,k)
N = length(X);

R_hat = 0;

for i = 1:N-abs(k)
R_hat = R_hat + (X(i)-mean(X)).*(X(i+abs(k))-mean(X));
end    

R_hat = R_hat/N;

R_hat;

