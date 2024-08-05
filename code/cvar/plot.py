import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from pandas.core.arrays.interval import ArrayLike

csv_file = 'experiments.csv'
df = pd.read_csv(csv_file)
# 3 columns in the csv file: 'Size,Fast_CVaR,Slow_CVaR'
# 'Size' is the x-axis, 'Fast_CVaR' and 'Slow_CVaR' are the y-axis
unique_sizes : ArrayLike = df['Size'].unique()
cis_slow_cvar = []
cis_fast_cvar = []
means_slow_cvar = []
means_fast_cvar = []
for size in unique_sizes:
    df_size = df[df['Size'] == size]
    ci_slow_cvar = 1.96 * (df_size['Slow_CVaR'].std() / np.sqrt(len(df_size['Slow_CVaR'])))
    ci_fast_cvar = 1.96 * (df_size['Fast_CVaR'].std() / np.sqrt(len(df_size['Fast_CVaR'])))
    cis_slow_cvar.append(ci_slow_cvar)
    cis_fast_cvar.append(ci_fast_cvar)
    means_slow_cvar.append(df_size['Slow_CVaR'].mean())
    means_fast_cvar.append(df_size['Fast_CVaR'].mean())

plt.errorbar(unique_sizes, means_slow_cvar, yerr=cis_slow_cvar, label='Slow_CVaR', color='red')
plt.errorbar(unique_sizes, means_fast_cvar, yerr=cis_fast_cvar, label='Fast_CVaR', color='green')
# plt.scatter(unique_sizes, means_slow_cvar, label='Slow_CVaR')
# plt.scatter(unique_sizes, means_fast_cvar, label='Fast_CVaR')
plt.xlabel('Size')
plt.ylabel('Time (s)')
plt.legend()
plt.savefig('plot.pdf')
plt.clf()
# please plot the ratio of Slow_CVaR to Fast_CVaR
ratios = np.array(means_slow_cvar) / np.array(means_fast_cvar)
plt.plot(unique_sizes, ratios, label='Slow_CVaR / Fast_CVaR')
plt.xlabel('Size')
plt.ylabel('Slow_CVaR / Fast_CVaR')
plt.legend()
plt.savefig('plot_ratio.pdf')
plt.clf()
# please plot the moving average of the ratio of Slow_CVaR to Fast_CVaR
window_size = 10
ratios_ma = np.convolve(ratios, np.ones(window_size), 'valid') / window_size
plt.plot(unique_sizes[window_size-1:], ratios_ma, label='Slow_CVaR / Fast_CVaR')
plt.xlabel('Size')
plt.ylabel('Slow_CVaR / Fast_CVaR')
plt.legend()
plt.savefig('plot_ratio_ma.pdf')
print('Done plotting')
