import matplotlib.pyplot as plt
import pandas as pd

csv_file = 'experiments.csv'
df = pd.read_csv(csv_file)
# 3 columns in the csv file: 'Size,Fast_CVaR,Slow_CVaR'
# 'Size' is the x-axis, 'Fast_CVaR' and 'Slow_CVaR' are the y-axis
plt.plot(df['Size'], df['Fast_CVaR'], label='Fast_CVaR')
plt.plot(df['Size'], df['Slow_CVaR'], label='Slow_CVaR')
plt.xlabel('Size')
plt.ylabel('Time (s)')
plt.legend()
plt.savefig('plot.pdf')
plt.clf()
plt.plot(df['Size'], df['Slow_CVaR'] / df['Fast_CVaR'], label='Slow_CVaR / Fast_CVaR')
plt.xlabel('Size')
plt.ylabel('Slow_CVaR / Fast_CVaR')
plt.legend()
plt.savefig('plot_ratio.pdf')
plt.clf()
# please plot the moving average of the ratio of Slow_CVaR to Fast_CVaR
plt.plot(df['Size'], df['Slow_CVaR'].rolling(window=1000).mean() / df['Fast_CVaR'].rolling(window=10).mean(), label='Slow_CVaR / Fast_CVaR')
plt.xlabel('Size')
plt.ylabel('Slow_CVaR / Fast_CVaR')
plt.legend()
plt.savefig('plot_ratio_ma.pdf')
