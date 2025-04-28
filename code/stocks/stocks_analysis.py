import pandas as pd
csv_file = "./stocks/stock_matchup.csv"
df = pd.read_csv(csv_file)
print(df.columns)
# divide by 1e9 since the values are in nanoseconds
df['cvar'] = df['cvar'] / 1e6
df['qcvar'] = df['qcvar'] / 1e6
df['var'] = df['var'] / 1e6
df['qvar'] = df['qvar'] / 1e6
df['tvar'] = df['tvar'] / 1e6
df['qtvar'] = df['qtvar'] / 1e6
# Group by timestep and calculate mean and standard deviation
grouped = df.groupby('n')
# for each col print mean and std
for col in df.columns:
    if col != 'n':
        # mean = grouped[col].mean()
        # std = grouped[col].std()
        # print(f"grouped{col}: mean = {mean}, std = {std}")
        mean = df[col].mean()
        std = df[col].std()
        print(f"non-grouped{col}: mean = {mean}, std = {std}")

 #Calculate mean and standard deviation for each of the methods
mean_std = df[['cvar', 'qcvar', 'var', 'qvar', 'tvar', 'qtvar']].agg(['mean', 'std'])

# Convert the mean and std-dev to milliseconds
mean_std_ms = mean_std * 1000  # Convert seconds to milliseconds

# Prepare the LaTeX table
latex_table = r"""
\begin{table}[ht]
\centering
\begin{tabular}{|c|c|c|c|c|c|c|}
\hline
Method & Mean (ms) & Std Dev (ms) \\
\hline
"""

# Add rows with the mean and std-dev values for each method
methods = ['CVaR', 'qCVaR', 'VaR', 'qVar', 'TVaR', 'qTVaR']
for i, method in enumerate(methods):
    mean_val = mean_std_ms.iloc[0, i]  # Mean value in ms
    std_val = mean_std_ms.iloc[1, i]   # Std-dev value in ms
    if 'q' in method:
        latex_table += f"\\textbf{{{method}}} & \\textbf{{{mean_val:.4f}}} & \\textbf{{{std_val:.4f}}} \\\\ \n"
    else:
        latex_table += f"{method} & {mean_val:.4f} & {std_val:.4f} \\\\ \n"

# Close the table
latex_table += r"""
\hline
\end{tabular}
\caption{Results for our Stock Market experiment.}
\end{table}
"""

# Output the LaTeX table
print(latex_table)
