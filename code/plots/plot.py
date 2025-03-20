import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from pandas.core.arrays.interval import ArrayLike
from sklearn.linear_model import LinearRegression

def plot_slow_vs_fast(csv_file: pd.DataFrame, slow_col: str, fast_col: str, slow_name: str, fast_name: str, special: str = ""):
    """
    Plot the comparison between slow and fast methods.
    in a log scale.
    and a linear scale.
    and save the plot in the plots folder.
    """
    # There may be multiple trials for the same n
    # We need to compute the mean and confidence interval
    unique_sizes = csv_file['n'].unique()
    cis_slow = []
    cis_fast = []
    means_slow = []
    means_fast = []
    for size in unique_sizes:
        df_size = df[df['n'] == size]
        ci_slow = 0.96 * (df_size[slow_col].std() / np.sqrt(len(df_size[slow_col])))
        ci_fast = 1.96 * (df_size[fast_col].std() / np.sqrt(len(df_size[fast_col])))
        cis_slow.append(ci_slow)
        cis_fast.append(ci_fast)
        means_slow.append(df_size['cvar'].mean())
        means_fast.append(df_size['qcvar'].mean())
    plt.plot(unique_sizes, means_slow, label=slow_name) # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_slow) - np.array(cis_slow), np.array(means_slow) + np.array(cis_slow), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, means_fast, label=fast_name)# pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_fast) - np.array(cis_fast), np.array(means_fast) + np.array(cis_fast), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('n')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.savefig(f'./plots/{slow_name}_vs_{fast_name}_{special}_log.pdf')
    plt.show()
    plt.clf()
    plt.plot(unique_sizes, means_slow, label=slow_name) # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_slow) - np.array(cis_slow), np.array(means_slow) + np.array(cis_slow), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, means_fast, label=fast_name)# pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_fast) - np.array(cis_fast), np.array(means_fast) + np.array(cis_fast), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.xlabel('n')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.savefig(f'./plots/{slow_name}_vs_{fast_name}_{special}_linear.pdf')
    plt.show()
    plt.clf()

def plot_cvar_div_qcvar(csv_file: pd.DataFrame):
    """
    Plot the ratio between CVaR and QCVaR
    Then fit a logaritmic function to the data
    and save the plot in the plots folder.
    """
    unique_sizes = csv_file['n'].unique()
    cvar_cis = []
    qcvar_cis = []
    cvar_means = []
    qcvar_means = []
    for size in unique_sizes:
        df_size = df[df['n'] == size]
        ci_cvar = 1.96 * (df_size['cvar'].std() / np.sqrt(len(df_size['cvar'])))
        ci_qcvar = 1.96 * (df_size['qcvar'].std() / np.sqrt(len(df_size['qcvar'])))
        cvar_cis.append(ci_cvar)
        qcvar_cis.append(ci_qcvar)
        cvar_means.append(df_size['cvar'].mean())
        qcvar_means.append(df_size['qcvar'].mean())
    X = np.array(np.log(unique_sizes)).reshape(-1, 1)
    Y = np.log(np.array(cvar_means)/np.array(qcvar_means))
    model = LinearRegression(fit_intercept=False).fit(X, Y)
    plt.plot(unique_sizes, np.array(cvar_means)/np.array(qcvar_means), label='CVaR/QCVaR') # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(cvar_means)/np.array(qcvar_means) - np.array(cvar_cis)/np.array(qcvar_means), np.array(cvar_means)/np.array(qcvar_means) + np.array(cvar_cis)/np.array(qcvar_means), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, np.exp(model.predict(X)), label='y = {:.2f} * log(n)'.format(model.coef_[0]))
    plt.xlabel('n')
    plt.ylabel('CVaR/QCVaR')
    plt.legend()
    plt.savefig('./plots/cvar_div_qcvar.pdf')
    plt.show()
    plt.clf()

if __name__ == "__main__":
    import os
    assert os.path.exists('./plots'), 'plots folder not found make sure you run this script from the fastcvar/code directory'
    assert os.path.exists('./plots/cvar_vs_qcvar_sparse.csv'), 'cvar_vs_qcvar.csv not found'
    assert os.path.exists('./plots/cvar_vs_qcvar_uniform.csv'), 'cvar_vs_qcvar.csv not found'
    slow = 'cvar','var','tvar'
    fast = 'qcvar','qvar','qtvar'
    # plot_cvar_div_qcvar(df)
    for dist in ['sparse', 'uniform']:
        csv_file = f"./plots/cvar_vs_qcvar_{dist}.csv"
        # Columns: n, cvar, qcvar
        # n: number of samples
        # cvar: Time to compute CVaR
        # qcvar: Time to compute QCVaR
        df = pd.read_csv(csv_file)
        for s, f in zip(slow, fast):
            plot_slow_vs_fast(df, s, f, s, f, dist)
