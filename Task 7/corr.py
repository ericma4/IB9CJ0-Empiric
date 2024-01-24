# this code check the correlation between original and replicated data.
import pandas as pd

# Load the data from the files
file1 = 'trace_2002_2021.h5'
file2 = 'trace_2002_2023.h5'

data1 = pd.read_hdf(file1)
data2 = pd.read_hdf(file2)

data2 = data2.reset_index()

# Filter the data before 2021-12
data1_filtered = data1[data1['date'] < '2022-01']
data2_filtered = data2[data2['date'] < '2022-01']

# Sort the data
data1_filtered = data1_filtered.sort_values(by=['cusip', 'date'])
data2_filtered = data2_filtered.sort_values(by=['cusip', 'date'])

data1_filtered = data1_filtered[~data1_filtered['bond_ret'].isnull()]
data2_filtered = data2_filtered[~data2_filtered['bond_ret'].isnull()]

merged_data = pd.merge(data1_filtered[['cusip', 'date', 'bond_ret']], data2_filtered[['cusip', 'date', 'bond_ret']], on=['cusip', 'date'], how='outer')

# Calculate the correlation of bond_ret
correlation = merged_data['bond_ret_x'].corr(merged_data['bond_ret_y'])

print(round(correlation, 4))