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
    def __init__(self, filename: str, df: pd.DataFrame, slow_cols: list[str], fast_cols: list[str], col2Name: dict[str, str], col2Marker: dict[str, str], col2Color: dict[str, str], special: str = ""):
        self.filename:str = filename
        self.df: pd.DataFrame = df 
        self.slow_cols: list[str] = slow_cols # which col is slow
        self.fast_cols: list[str] = fast_cols # which col is fast
        self.col2Name: dict[str, str] = col2Name # column name to display on graph
        self.col2Marker: dict[str, str] = col2Marker # column name to display on graph
        self.col2Color: dict[str, str] = col2Color
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
        for col in self.slow_cols + self.fast_cols:
            cis = []
            means = []
            for size in unique_sizes:
                df_size = df[df['n'] == size]
                ci_slow = 1.96 * (df_size[col].std() / (np.sqrt(len(df_size[col]))-1))
                cis.append(ci_slow)
                means.append(df_size[col].mean())
            results[col] = (cis, means)
        return results

def plot_means_and_cis(plotter: Plotter, col: str):
    unique_sizes = plotter.df['n'].unique()
    cis, means = plotter.CI[col]
    plt.plot(unique_sizes, means, label=plotter.col2Name[col], marker=plotter.col2Marker[col], color=plotter.col2Color[col]) # pyright: ignore[reportArgumentType]
    plt.fill_between(unique_sizes, np.array(means) - np.array(cis), np.array(means) + np.array(cis), alpha=0.2, color=plotter.col2Color[col])# pyright: ignore[reportArgumentType]

def plot_one_slow_vs_fast(plotter: Plotter, slow: str, fast: str):
    """
    Plot the comparison between one pair of slow and fast methods.
    in a log scale.
    and a linear scale.
    """
    # There may be multiple trials for the same n
    # We need to compute the mean and confidence interval
    plot_means_and_cis(plotter, slow)
    plot_means_and_cis(plotter, fast)
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/( plotter.slow_name )_vs_(plotter.fast_name)_{plotter.special}_log.pdf')
    # plt.show()
    plt.clf()
    plot_means_and_cis(plotter, slow)
    plot_means_and_cis(plotter, fast)
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
    for slow in plotter.slow_cols:
        plot_means_and_cis(plotter, slow)
    for fast in plotter.fast_cols:
        plot_means_and_cis(plotter, fast)
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('Length of Random Variable (n)')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.grid()
    plt.savefig(f'./plots/all_slow_vs_fast_{plotter.special}_log.pdf')
    # plt.show()
    plt.clf()
    for slow in plotter.slow_cols:
        plot_means_and_cis(plotter, slow)
    for fast in plotter.fast_cols:
        plot_means_and_cis(plotter, fast)
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
    plt.legend()
    plt.savefig('./plots/cvar_div_qcvar.pdf')
    # plt.show()
    plt.clf()

if __name__ == "__main__":
    import os
    assert os.path.exists('./plots'), 'plots folder not found make sure you run this script from the fastcvar/code directory'
    assert os.path.exists('./plots/cvar_vs_qcvar_uniform.csv'), 'cvar_vs_qcvar.csv not found'
    slow = ['cvar','var','tvar']
    fast = ['qcvar','qvar','qtvar', 'expectation']
    col2Name = {'cvar': 'CVaR', 'qcvar': 'QCVaR', 'var': 'VaR', 'qvar': 'QVaR', 'tvar': 'TVaR', 'qtvar': 'QTVaR', 'expectation': 'E'}
    col2Color = {'cvar': 'blue', 'qcvar': 'blue', 'var': 'green', 'qvar': 'green', 'tvar': 'purple', 'qtvar': 'purple', 'expectation': 'pink'}
    # markers = ["o", "v", "s", "P", "X", "D", "p", "*", "h", "H", "d", "8"]
    col2Marker = {'cvar': 'o', 'qcvar': '*', 'var': 's', 'qvar': 'P', 'tvar': 'X', 'qtvar': 'D', 'expectation': 'p'}
    # plot_cvar_div_qcvar(df)
    for dist in ['sparse', 'uniform']:
        csv_file = f"./plots/cvar_vs_qcvar_{dist}.csv"
        # Columns: n, cvar, qcvar
        # n: number of samples
        # cvar: Time to compute CVaR
        # qcvar: Time to compute QCVaR
        df = pd.read_csv(csv_file)
        plotter = Plotter(csv_file, df, slow, fast, col2Name, col2Marker, col2Color, dist)
        plot_all_slow_vs_fast(plotter)
    csv_file = "./plots/cvar_vs_qcvar_for_log_fit.csv"
    df = pd.read_csv(csv_file)
    plotter = Plotter(csv_file, df, ["cvar"], ["qcvar"], col2Name, col2Marker, col2Color, "")
    plot_cvar_div_qcvar(plotter)
