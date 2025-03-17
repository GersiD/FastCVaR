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
    plt.plot(csv_file['n'], csv_file['cvar'], label='CVaR')
    plt.plot(csv_file['n'], csv_file['qcvar'], label='QCVaR')
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('n')
    plt.ylabel('Time (ms)')
    plt.legend()
    plt.title('CVaR vs QCVaR')
    plt.savefig('./plots/cvar_vs_qcvar_log.pdf')
    plt.show()
    plt.clf()
    plt.plot(csv_file['n'], csv_file['cvar'], label='CVaR')
    plt.plot(csv_file['n'], csv_file['qcvar'], label='QCVaR')
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
    X = np.array(np.log(csv_file['n'])).reshape(-1, 1)
    Y = np.log(csv_file['cvar']/csv_file['qcvar'])
    model = LinearRegression(fit_intercept=False).fit(X, Y)
    plt.plot(csv_file['n'], csv_file['cvar']/csv_file['qcvar'],  label='CVaR/QCVaR')
    plt.plot(csv_file['n'], np.exp(model.predict(X)), label='y = {:.2f} * log(n)'.format(model.coef_[0]))
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
