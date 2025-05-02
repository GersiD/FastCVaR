import pandas as pd

csv_file = "./small_cases/cvar_vs_qcvar_uniform.csv"
df = pd.read_csv(csv_file)

# Group by 'n' and calculate mean and std
grouped = df.groupby('n').agg(['mean', 'std'])

# Flatten the MultiIndex columns for easier access
grouped.columns = ['_'.join(col).strip() for col in grouped.columns.values]

# Build a new DataFrame with formatted "mean ± std" strings
formatted_df = pd.DataFrame(index=grouped.index)

bold_cols = ['qcvar', 'qvar', 'qtvar']
for col in grouped.columns:
    if col.endswith('_mean'):
        base = col[:-5]
        std_col = f"{base}_std"
        def format_row(row):
            val = f"{row[col]:.2f} ± {(1.96*row[std_col]):.2f}"
            return f"\\textbf{{{val}}}" if base in bold_cols else val
        formatted_df[base] = grouped.apply(format_row, axis=1)

# Convert to LaTeX
latex_table = formatted_df.to_latex(
    index=True,
    column_format="l" + "c" * formatted_df.shape[1],
    caption="Mean time (ms) ± 95\\% standard deviation of each method.",
    escape=False  # Allow ± to render properly in LaTeX
)

print(latex_table)
