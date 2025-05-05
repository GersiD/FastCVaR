import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

csv_file = './cvar_evar_tvar/cvar_vs_qcvar_uniform.csv'
df = pd.read_csv(csv_file)
#columns n,cvar,qcvar,tvar,qtvar,evar
df['evar_bound'] = df['cvar'] + df['tvar']
df['qevar_bound'] = df['qcvar'] + df['qtvar']
ns = df['n'].unique()
grouped = df.groupby('n')
means = grouped.mean()
stds = grouped.std()
counts = grouped.count()
ci = 1.96 * stds.divide(np.sqrt(counts), axis=0) # pyright: ignore[reportAttributeAccessIssue]
method_to_label = {
    'evar': 'EVaR',
    'evar_bound': 'EVaR Bound',
    'qevar_bound': 'QEVaR Bound'
}
# Set the font type to TrueType Globally
plt.rcParams['pdf.fonttype'] = 42
plt.rcParams['ps.fonttype'] = 42
# set the font to be Computer Modern (cmr10 doesnt work so we use serif)
plt.rcParams['axes.formatter.use_mathtext'] = True
plt.rcParams["font.family"] = "serif"
# set font size
plt.rcParams["font.size"] = 18
# set the figure size
plt.rcParams["figure.figsize"] = (8.3, 6.0)
# plot each col mean with 95% confidence interval
for method in ['evar', 'evar_bound', 'qevar_bound']:
    plt.plot(ns, means[method], label=method_to_label[method]) # pyright: ignore[reportArgumentType]
    plt.fill_between(ns, means[method] - ci[method], means[method] + ci[method], alpha=0.2) # pyright: ignore[reportArgumentType]
plt.xlabel('Length of Random Variable (n)')
plt.ylabel('Time (ms)')
plt.legend()
plt.grid()
plt.savefig('./cvar_evar_tvar/cvar_vs_qcvar_uniform.pdf')
plt.show()
