import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from pandas.core.arrays.interval import ArrayLike
from sklearn.linear_model import LinearRegression

def plot_cvar_vs_qcvar_log_linear(csv_file: pd.DataFrame):
    """
    Plot the comparison between CVaR and QCVaR
    in a log scale.
    and a linear scale.
    and save the plot in the plots folder.
    """
    # There may be multiple trials for the same n
    # We need to compute the mean and confidence interval
    unique_sizes = csv_file['n'].unique()
    cis_slow_cvar = []
    cis_fast_cvar = []
    means_slow_cvar = []
    means_fast_cvar = []
    for size in unique_sizes:
        df_size = df[df['n'] == size]
        ci_slow_cvar = 1.96 * (df_size['cvar'].std() / np.sqrt(len(df_size['cvar'])))
        ci_fast_cvar = 1.96 * (df_size['qcvar'].std() / np.sqrt(len(df_size['qcvar'])))
        cis_slow_cvar.append(ci_slow_cvar)
        cis_fast_cvar.append(ci_fast_cvar)
        means_slow_cvar.append(df_size['cvar'].mean())
        means_fast_cvar.append(df_size['qcvar'].mean())
    plt.plot(unique_sizes, means_slow_cvar, label='CVaR') # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_slow_cvar) - np.array(cis_slow_cvar), np.array(means_slow_cvar) + np.array(cis_slow_cvar), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, means_fast_cvar, label='QCVaR')# pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_fast_cvar) - np.array(cis_fast_cvar), np.array(means_fast_cvar) + np.array(cis_fast_cvar), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('n')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.title('CVaR vs QCVaR')
    plt.savefig('./plots/cvar_vs_qcvar_log.pdf')
    plt.show()
    plt.clf()
    plt.plot(unique_sizes, means_slow_cvar, label='CVaR') # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_slow_cvar) - np.array(cis_slow_cvar), np.array(means_slow_cvar) + np.array(cis_slow_cvar), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, means_fast_cvar, label='QCVaR')# pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_fast_cvar) - np.array(cis_fast_cvar), np.array(means_fast_cvar) + np.array(cis_fast_cvar), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.xlabel('n')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.title('CVaR vs QCVaR')
    plt.savefig('./plots/cvar_vs_qcvar_linear.pdf')
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
    plt.title('CVaR/QCVaR')
    plt.savefig('./plots/cvar_div_qcvar.pdf')
    plt.show()
    plt.clf()

if __name__ == "__main__":
    import os
    assert os.path.exists('./plots'), 'plots folder not found make sure you run this script from the fastcvar/code directory'
    assert os.path.exists('./plots/cvar_vs_qcvar.csv'), 'cvar_vs_qcvar.csv not found'
    csv_file = "./plots/cvar_vs_qcvar.csv"
    # Columns: n, cvar, qcvar
    # n: number of samples
    # cvar: Time to compute CVaR
    # qcvar: Time to compute QCVaR
    df = pd.read_csv(csv_file)
    plot_cvar_vs_qcvar_log_linear(df)
    plot_cvar_div_qcvar(df)
