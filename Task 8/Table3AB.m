% addpath(genpath('Data'));
addpath(genpath('Functions'));
%   Table3AB.m    
%   "Table 3: Risk premia and CSR R2s for traded-factor models." 
%   Date: 28/07/2023
%   Authors: C. Robotti (Edited by A. Dickerson)
%   Table 3 Panels A & B from:
%   "Priced risk in corporate bonds" by
%   A.Dickerson, P. Mueller & C. Robotti

%   What does this file do?
%   This file computes the price of beta risk using both OLS
%   and GLS using the set of basis assets from DMR and the repsective
%   factor models. The file also outputs the R-squared.

%   Panel A: Computes the Price of Beta Risk (OLS) across DMR models with
%   t-statistics computed as in Kan, Robotti and Shanken (2013, KRS).

%   Panel B: Computes the Price of Beta Risk (GLS) across DMR models with
%   t-statistics computed as in KRS.

% Set lag length to 3
nlag = 3;

% Set date end %
% For end date co-inciding with BBW (2016-12-31)
% Start date of all models is (2004-08-31), T == 149
% Load all factors/portfolios %
data_in_factors    = 'bbw4.csv';
data_in_portfolios = 'portfolios.csv';

% To exactly replicate the Table 1, set Te = 60.
% If you want to examine the statistics for ther sample up until 2021:12,
% then set Te = 0.
Te = 0; % With Te = 60, the sample is 2004:08-2016:12

bbw     = importdata(data_in_factors,',');
names   = bbw.textdata(1,2:end);
date    = bbw.textdata(2:(end-Te),1);

mktb    = bbw.data(1:(end-Te),1);

% Factors stored in BigF %
BigF    = [mktb];

% Load all portfolios %
portfolios = importdata(data_in_portfolios,',');
rx_combi   = portfolios.data(1:(end-Te),:);
R = rx_combi;

N = size(R,2);
fprintf('                                                         \n')
fprintf('                                                         \n')
fprintf('Table 3: Risk premia and CSR R2s for traded-factor models \n')
fprintf(' Period:  2004:8-2022:12\n')
fprintf(' Cross-section: %s \n', '32 combo')
fprintf(' Number of lags = %2.0f\n',nlag)
fprintf(' Number of assets = %2.0f\n',N)
fprintf('                                                         \n')

modelind = NaN(6,5);
modelind(1,1)   = 1;                   % MKTB

nmodel = 1;

% Set rf to zero %
rf = 0;

for jj=1:2
    Gamma_Export   = [];
    tRatio3_Export = [];
    tRatio4_Export = [];

    if jj==1
       fprintf('Table 3 Panel A OLS CSR\n')
       fcn = 'csrw';
    else
       fprintf('\n Table 3 Panel B GLS CSR\n')
       fcn = 'csrgls';
    end
    fprintf(' Gamma:\n')
    for ii=1:nmodel
        if ii==1
           fprintf('\n MKTB\n')
           fprintf('      Const     MKTB\n')
        end
        
        m = modelind(ii,:);
        m(isnan(m)) = [];
        F = BigF(:,m);
        [R2,~,pval1b,~,~,~,~,~,gamma,trat1,trat2,trat3,trat4] = feval(fcn,R,F,nlag);
        % Test if \gamma_0 is equal to the average risk-free rate
        trat1(1) = (1-rf/gamma(1))*trat1(1);
        trat2(1) = (1-rf/gamma(1))*trat2(1);
        trat3(1) = (1-rf/gamma(1))*trat3(1);
        trat4(1) = (1-rf/gamma(1))*trat4(1);
        Rsqr(1)  = R2;
        R2pval(1)= pval1b;
        fprintf('    ')
        for i=1:length(m)+1
            fprintf('%7.2f  ',gamma(i)*100)
        end
        fprintf('\n     ')
        for i=1:length(m)+1
            fprintf('(%5.2f)  ',trat3(i))
        end
        fprintf('\n     ')
        for i=1:length(m)+1
            fprintf('(%5.2f)  ',trat4(i))
        end
        fprintf('\n     ')
        fprintf(' %5.3f  ',Rsqr(1))
        fprintf('\n     ')
        fprintf('[%5.3f]  ',R2pval(1))

        fprintf('\n')

        if length(gamma) < 5
            gamma = [gamma ; NaN(5 - length(gamma),1)];
            trat3 = [trat3 ; NaN(5 - length(trat3),1)];
            trat4 = [trat4 ; NaN(5 - length(trat4),1)];
        end

        Gamma_Export   = [Gamma_Export   gamma];
        tRatio3_Export = [tRatio3_Export trat3];
        tRatio4_Export = [tRatio4_Export trat4];
    end    

    if jj == 1
        OLS_Gamma    = round(Gamma_Export.*100, 2)';
        OLS_Gamma_t3 = round(tRatio3_Export, 2)';
        OLS_Gamma_t4 = round(tRatio4_Export, 2)';
    elseif jj ==2
        GLS_Gamma    = round(Gamma_Export.*100, 2)';
        GLS_Gamma_t3 = round(tRatio3_Export, 2)';
        GLS_Gamma_t4 = round(tRatio4_Export, 2)';
    end


end
