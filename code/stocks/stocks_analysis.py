import pandas as pd
csv_file = "./stocks/stock_matchup.csv"
df = pd.read_csv(csv_file)
print(df.columns)
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
mean_std = df[['cvar', 'qcvar', 'var', 'qvar', 'tvar', 'qtvar', 'expectation']].agg(['mean', 'std'])

# Prepare the LaTeX table
latex_table = r"""
\begin{table}
\centering
\begin{tabular}{lrr}
\toprule
Method & Mean (ms) & Std Dev (ms) \\
"""

# Add rows with the mean and std-dev values for each method
methods = ['CVaR', 'qCVaR', 'VaR', 'qVar', 'TVaR', 'qTVaR', 'Expectation']
for i, method in enumerate(methods):
    if i % 2 ==0:
        latex_table += "\\midrule \n"
    mean_val = mean_std.iloc[0, i]  # Mean value in ms
    std_val = mean_std.iloc[1, i]   # Std-dev value in ms
    if 'q' in method:
        latex_table += f"\\textbf{{{method}}} & \\textbf{{{mean_val:.4f}}} & \\textbf{{{std_val:.4f}}} \\\\ \n"
    else:
        latex_table += f"{method} & {mean_val:.4f} & {std_val:.4f} \\\\ \n"

# Close the table
latex_table += r"""
\bottomrule
\end{tabular}
\caption{Results for our Stock Market experiment.}
\end{table}
"""

# Output the LaTeX table
print(latex_table)
