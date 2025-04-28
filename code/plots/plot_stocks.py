import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

# Load the CSV with the results (assuming the file is named 'experiment_runtimes_with_ids.csv')
df = pd.read_csv("./plots/stock_matchup.csv")

# Group by timestep and calculate mean and standard deviation
grouped = df.groupby('n').agg(
    slow_cvar_mean=('cvar', 'mean'),
    fast_cvar_mean=('qcvar', 'mean'),
    var_mean=('var', 'mean'),
    qvar_mean=('qvar', 'mean'),
    tvar_mean=('tvar', 'mean'),
    qtvar_mean=('qtvar', 'mean'),
    
    slow_cvar_std=('cvar', 'std'),
    fast_cvar_std=('qcvar', 'std'),
    var_std=('var', 'std'),
    qvar_std=('qvar', 'std'),
    tvar_std=('tvar', 'std'),
    qtvar_std=('qtvar', 'std')
)

# Calculate 95% Confidence Intervals using the standard error of the mean (SEM)
# SEM = std / sqrt(n)
n_trials = df['n'].nunique()  # Number of trials per timestep

grouped['slow_cvar_ci'] = 1.96 * (grouped['slow_cvar_std'] / np.sqrt(n_trials))
grouped['fast_cvar_ci'] = 1.96 * (grouped['fast_cvar_std'] / np.sqrt(n_trials))
grouped['var_ci'] = 1.96 * (grouped['var_std'] / np.sqrt(n_trials))
grouped['qvar_ci'] = 1.96 * (grouped['qvar_std'] / np.sqrt(n_trials))
grouped['tvar_ci'] = 1.96 * (grouped['tvar_std'] / np.sqrt(n_trials))
grouped['qtvar_ci'] = 1.96 * (grouped['qtvar_std'] / np.sqrt(n_trials))

# Plotting: For example, plotting the confidence intervals for slow_cvar_time vs fast_cvar_time
plt.figure(figsize=(10, 6))

# Plot each method with fill_between for confidence intervals
plt.plot(grouped.index, grouped['slow_cvar_mean'], label='Slow CVaR', color='blue', lw=2)
plt.fill_between(grouped.index, grouped['slow_cvar_mean'] - grouped['slow_cvar_ci'], 
                 grouped['slow_cvar_mean'] + grouped['slow_cvar_ci'], color='blue', alpha=0.3)

plt.plot(grouped.index, grouped['fast_cvar_mean'], label='Fast qCVaR', color='red', lw=2)
plt.fill_between(grouped.index, grouped['fast_cvar_mean'] - grouped['fast_cvar_ci'], 
                 grouped['fast_cvar_mean'] + grouped['fast_cvar_ci'], color='red', alpha=0.3)

plt.plot(grouped.index, grouped['var_mean'], label='VaR', color='green', lw=2)
plt.fill_between(grouped.index, grouped['var_mean'] - grouped['var_ci'], 
                 grouped['var_mean'] + grouped['var_ci'], color='green', alpha=0.3)

plt.plot(grouped.index, grouped['qvar_mean'], label='qVar', color='orange', lw=2)
plt.fill_between(grouped.index, grouped['qvar_mean'] - grouped['qvar_ci'], 
                 grouped['qvar_mean'] + grouped['qvar_ci'], color='orange', alpha=0.3)

plt.plot(grouped.index, grouped['tvar_mean'], label='TVaR', color='purple', lw=2)
plt.fill_between(grouped.index, grouped['tvar_mean'] - grouped['tvar_ci'], 
                 grouped['tvar_mean'] + grouped['tvar_ci'], color='purple', alpha=0.3)

plt.plot(grouped.index, grouped['qtvar_mean'], label='qTVaR', color='brown', lw=2)
plt.fill_between(grouped.index, grouped['qtvar_mean'] - grouped['qtvar_ci'], 
                 grouped['qtvar_mean'] + grouped['qtvar_ci'], color='brown', alpha=0.3)


# Customize plot
plt.xlabel('Timestep')
plt.ylabel('Time (seconds)')
plt.title('Risk Measure Time Comparisons with 95% Confidence Intervals')
plt.legend()
plt.grid(True)

# Show plot
plt.tight_layout()
plt.savefig('./plots/stock_matchup.pdf')
plt.show()

