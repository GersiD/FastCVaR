from collections import defaultdict
import matplotlib.pyplot as plt
from numpy.ma import mean
import pandas as pd
import numpy as np
from pandas.core.arrays.interval import ArrayLike
from sklearn.linear_model import LinearRegression
from typing import Tuple

from sklearn.utils.sparsefuncs import mean_variance_axis

class Plotter(object):
    """Wrapper class that keeps track of a dataset and its info for plotting"""
    def __init__(self, filename: str, df: pd.DataFrame, slow_cols: list[str], fast_cols: list[str], col2Name: dict[str, str], col2Marker: dict[str, str], special: str = ""):
        self.filename:str = filename
        self.df: pd.DataFrame = df 
        self.slow_cols: list[str] = slow_cols # which col is slow
        self.fast_cols: list[str] = fast_cols # which col is fast
        self.col2Name: dict[str, str] = col2Name # column name to display on graph
        self.col2Marker: dict[str, str] = col2Marker # column name to display on graph
        self.special:str = special # e.g. 'uniform', 'sparse' for final filename
        self.CI = self.compute_cis_means() # confidence intervals for each method
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

    def compute_cis_means(self) -> dict[str, Tuple[float, float]]:
        """
        Compute the confidence intervals and means for the slow and fast methods
        """
        results: dict[str, tuple] = defaultdict(tuple)
        unique_sizes = self.df['n'].unique()
        for slow_col, fast_col in zip(self.slow_cols, self.fast_cols):
            cis_slow = []
            cis_fast = []
            means_slow = []
            means_fast = []
            for size in unique_sizes:
                df_size = df[df['n'] == size]
                ci_slow = 1.96 * (df_size[slow_col].std() / (np.sqrt(len(df_size[slow_col]))-1))
                ci_fast = 1.96 * (df_size[fast_col].std() / (np.sqrt(len(df_size[fast_col]))-1))
                cis_slow.append(ci_slow)
                cis_fast.append(ci_fast)
                means_slow.append(df_size[slow_col].mean())
                means_fast.append(df_size[fast_col].mean())
            results[slow_col] = (cis_slow, means_slow)
            results[fast_col] = (cis_fast, means_fast)
        return results

def plot_slow_vs_fast_data(plotter: Plotter, slow: str, fast: str):
    """
    Load the slow and fast data into the plt object for the caller to configure and plot.
    """
    unique_sizes = plotter.df['n'].unique()
    cis_slow, means_slow = plotter.CI[slow]
    cis_fast, means_fast = plotter.CI[fast]
    plt.plot(unique_sizes, means_slow, label=plotter.col2Name[slow], marker=plotter.col2Marker[slow]) # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_slow) - np.array(cis_slow), np.array(means_slow) + np.array(cis_slow), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, means_fast, label=plotter.col2Name[fast], marker=plotter.col2Marker[fast])# pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means_fast) - np.array(cis_fast), np.array(means_fast) + np.array(cis_fast), alpha=0.2)# pyright: ignore[reportArgumentType]

def plot_one_slow_vs_fast(plotter: Plotter, slow: str, fast: str):
    """
    Plot the comparison between one pair of slow and fast methods.
    in a log scale.
    and a linear scale.
    """
    # There may be multiple trials for the same n
    # We need to compute the mean and confidence interval
    plot_slow_vs_fast_data(plotter, slow, fast)
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/( plotter.slow_name )_vs_(plotter.fast_name)_{plotter.special}_log.pdf')
    # plt.show()
    plt.clf()
    plot_slow_vs_fast_data(plotter, slow, fast)
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/{plotter.col2Name[slow]}_vs_{plotter.col2Name[fast]}_{plotter.special}_linear.pdf')
    # plt.show()
    plt.clf()

def plot_all_slow_vs_fast(plotter: Plotter):
    """
    Plot the comparison between all slow and fast methods.
    in a log scale.
    and a linear scale.
    """
    for slow, fast in zip(plotter.slow_cols, plotter.fast_cols):
        plot_slow_vs_fast_data(plotter, slow, fast)
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/all_slow_vs_fast_{plotter.special}_log.pdf')
    # plt.show()
    plt.clf()
    for slow, fast in zip(plotter.slow_cols, plotter.fast_cols):
        plot_slow_vs_fast_data(plotter, slow, fast)
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/all_slow_vs_fast_{plotter.special}_linear.pdf')
    # plt.show()
    plt.clf()

def plot_cvar_div_qcvar(plotter: Plotter):
    """
    Plot the ratio between CVaR and QCVaR
    Then fit a logaritmic function to the data
    and save the plot in the plots folder.
    """
    unique_sizes = plotter.df['n'].unique()
    plotter.df['cvar/qcvar'] = plotter.df['cvar'] / plotter.df['qcvar']
    cvar_div_qcvar_cis = []
    cvar_div_qcvar_means = []
    for size in unique_sizes:
        df_size = plotter.df[plotter.df['n'] == size]
        cvar_div_qcvar_ci = 1.96 * (df_size['cvar/qcvar'].std() / (np.sqrt(len(df_size['cvar/qcvar']))-1))
        cvar_div_qcvar_cis.append(cvar_div_qcvar_ci)
        cvar_div_qcvar_mean = df_size['cvar/qcvar'].mean()
        cvar_div_qcvar_means.append(cvar_div_qcvar_mean)
    X = np.array(np.log(unique_sizes)).reshape(-1, 1)
    Y = np.log(np.array(cvar_div_qcvar_means))
    model = LinearRegression(fit_intercept=False).fit(X, Y)
    plt.plot(unique_sizes, np.array(cvar_div_qcvar_means), label='Time CVaR / Time QCVaR') # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(cvar_div_qcvar_means) - np.array(cvar_div_qcvar_cis), np.array(cvar_div_qcvar_means) + np.array(cvar_div_qcvar_cis), alpha=0.2)# pyright: ignore[reportArgumentType]
    plt.plot(unique_sizes, np.exp(model.predict(X)), label='y = {:.2f} * log(n)'.format(model.coef_[0]))# pyright: ignore[reportArgumentType]
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.savefig('./plots/cvar_div_qcvar.pdf')
    # plt.show()
    plt.clf()

if __name__ == "__main__":
    import os
    assert os.path.exists('./plots'), 'plots folder not found make sure you run this script from the fastcvar/code directory'
    assert os.path.exists('./plots/cvar_vs_qcvar_sparse.csv'), 'cvar_vs_qcvar.csv not found'
    assert os.path.exists('./plots/cvar_vs_qcvar_uniform.csv'), 'cvar_vs_qcvar.csv not found'
    slow = ['cvar','var','tvar']
    fast = ['qcvar','qvar','qtvar']
    col2Name = {'cvar': 'CVaR', 'qcvar': 'QCVaR', 'var': 'VaR', 'qvar': 'QVaR', 'tvar': 'TVaR', 'qtvar': 'QTVaR'}
    # markers = ["o", "v", "s", "P", "X", "D", "p", "*", "h", "H", "d", "8"]
    col2Marker = {'cvar': 'o', 'qcvar': '*', 'var': 's', 'qvar': 'P', 'tvar': 'X', 'qtvar': 'D'}
    # plot_cvar_div_qcvar(df)
    for dist in ['sparse', 'uniform']:
        csv_file = f"./plots/cvar_vs_qcvar_{dist}.csv"
        # Columns: n, cvar, qcvar
        # n: number of samples
        # cvar: Time to compute CVaR
        # qcvar: Time to compute QCVaR
        df = pd.read_csv(csv_file)
        plotter = Plotter(csv_file, df, slow, fast, col2Name, col2Marker, dist)
        plot_all_slow_vs_fast(plotter)
    csv_file = "./plots/cvar_vs_qcvar_for_log_fit.csv"
    df = pd.read_csv(csv_file)
    plotter = Plotter(csv_file, df, ["cvar"], ["qcvar"], col2Name, col2Marker, "")
    plot_cvar_div_qcvar(plotter)
