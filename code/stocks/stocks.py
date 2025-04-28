# import modules 
from datetime import datetime
import yfinance as yf
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# initialize parameters 
start_date = datetime(2025, 3, 1)
end_date = datetime(2025, 4, 27)

# get the data 
data = yf.download('SPY', start = start_date, end = end_date, interval='5m')
if data is None:
    raise ValueError("No data found for the given date range.")

# display 
# plt.figure(figsize = (20,10))
# plt.title('Opening Prices from {} to {}'.format(start_date, end_date))
# plt.plot(data['Open'])
# plt.savefig('./stocks/plots/spy_opening_prices.png')
# plt.show()

# calculate the returns
if 'Close' not in data.columns:
    raise ValueError(f"Expected 'Close' column but got {data.columns.tolist()}")
prices = data['Close'].to_numpy().flatten()
returns = np.diff(prices) # pyright: ignore[reportArgumentType]
data['Returns'] = np.append([0.0], returns) # add NaN for the first row
# calculate the means and std devs
window = 10
data['Mean'] = data['Returns'].rolling(window=window).mean()
data['Std'] = data['Returns'].rolling(window=window).std()
print(data.columns)
print(data.head())
print("Number of Rows: ", len(data))

# Save the data to a CSV file
data.to_csv('./stocks/spy_data.csv')
