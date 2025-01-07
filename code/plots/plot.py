import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from pandas.core.arrays.interval import ArrayLike

def plot_cvar_vs_qcvar_log_linear(csv_file: pd.DataFrame):
    """
    Plot the comparison between CVaR and QCVaR
    in a log scale.
    and a linear scale.
    and save the plot in the plots folder.
    """
    plt.plot(csv_file['n'], csv_file['cvar'], label='CVaR')
    plt.plot(csv_file['n'], csv_file['qcvar'], label='QCVaR')
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('n')
    plt.ylabel('Time (s)')
    plt.legend()
    plt.title('CVaR vs QCVaR')
    plt.savefig('./plots/cvar_vs_qcvar_log.png')
    plt.show()
    plt.clf()
    plt.plot(csv_file['n'], csv_file['cvar'], label='CVaR')
    plt.plot(csv_file['n'], csv_file['qcvar'], label='QCVaR')
    plt.xlabel('n')
    plt.ylabel('Time (s)')
    plt.legend()
    plt.title('CVaR vs QCVaR')
    plt.savefig('./plots/cvar_vs_qcvar_linear.png')
    plt.show()
    plt.clf()

def plot_cvar_div_qcvar(csv_file: pd.DataFrame):
    """
    Plot the ratio between CVaR and QCVaR
    and save the plot in the plots folder.
    """
    plt.plot(csv_file['n'], csv_file['cvar']/csv_file['qcvar'])
    plt.xlabel('n')
    plt.ylabel('CVaR/QCVaR')
    plt.title('CVaR/QCVaR')
    plt.savefig('./plots/cvar_div_qcvar.png')
    plt.show()
    plt.clf()

if __name__ == "__main__":
    import os
    assert os.path.exists('./plots/cvar_vs_qcvar.csv'), 'cvar_vs_qcvar.csv not found'
    csv_file = "./plots/cvar_vs_qcvar.csv"
    # Columns: n, cvar, qcvar
    # n: number of samples
    # cvar: Time to compute CVaR
    # qcvar: Time to compute QCVaR
    df = pd.read_csv(csv_file)
    plot_cvar_vs_qcvar_log_linear(df)
    plot_cvar_div_qcvar(df)
