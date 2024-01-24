import pandas as pd
import numpy as np
from tqdm import tqdm
tqdm.pandas()
import statsmodels.api as sm

data = pd.read_hdf('trace_2002_2023.h5')
data = data.reset_index()

# ret = 'exretn_t+1'

def mom(start, end, df):
    """

    :param start: Order of starting lag
    :param end: Order of ending lag
    :param df: Dataframe
    :return: Momentum
    """
    lag = pd.DataFrame()
    result = 1
    end = end + 1  # adjust for the range function
    for i in range(start, end):
        print(i)
        lag['mom%s' % i] = df.groupby(['cusip'])['exretn'].shift(i)
        lag['date_check'] = df.groupby(['cusip'])['date_diff'].shift(i)
        # when the gap between two months is less than 40 days, we use the lagged return
        lag['mom%s' % i] = np.where(lag['date_check'] < pd.Timedelta(days=40), lag['mom%s' % i], np.nan)
        result = result * (1+lag['mom%s' % i])
    result = result - 1
    return result


# Data cleaning
data = data[data['date'] <= '2022-12-31']

data = data[~data['exretn_t+1'].isnull()]
data = data.sort_values(by=['cusip', 'date'])
data['date_lag'] = data.groupby(['cusip'])['date'].shift(1)
data['date_diff'] = data['date'] - data['date_lag']  # check if last month has transaction

# Calculate momentum
data['mom'] = mom(1, 6, data)
data = data[~data['mom'].isnull()]

# Calculate quantile
data['momQ'] = data.groupby(by='date')['mom'].progress_apply(lambda x: pd.qcut(x,10,labels=False,duplicates='drop')+1)

# Sorting portfolios    
sorts = data.groupby(['date','momQ'])['exretn_t+1'].progress_apply(lambda x: np.mean(x)).to_frame()
sorts  = sorts.pivot_table(index = ['date'],columns = ['momQ'], values = 'exretn_t+1')
sorts = sorts.reset_index()
sorts = sorts.drop(['date'], axis=1)

sorts['diff'] = sorts[10] - sorts[1]
sorts = sorts*100
Table_mom = pd.DataFrame(sorts.mean().round(2))
Table_mom['t-stat'] = np.nan

# t-stat
sorts['const'] = 1
count = 0
for i in range(11):
    results = sm.OLS(sorts.iloc[:, i], sorts['const']).fit(cov_type='HAC',cov_kwds={'maxlags':12})
    t_stat = results.tvalues[0]
    Table_mom.iloc[count, 1] = t_stat.round(2)
    count += 1


print(Table_mom.T)