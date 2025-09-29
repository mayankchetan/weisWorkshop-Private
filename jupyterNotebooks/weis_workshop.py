# Simple Colab detection
import sys
import numpy as np
import matplotlib.pyplot as plt
import openmdao.api as om


# Global variable to check if we're in Google Colab
IN_COLAB = 'google.colab' in sys.modules

if IN_COLAB:
    print("Running in Google Colab")
else:
    print("Running in local environment")

def plotter(x,y, xlabel, ylabel, title, ax=None, label=None):
    if ax is None:
        return None

    ax.plot(np.array(eval(x)), np.array(eval(y)), label=label)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    if label:
        ax.legend()
    return ax

# This function loads the openmdao sql file and does most of the work here
def load_OMsql(log):
    print('loading {}'.format(log))
    cr = om.CaseReader(log)
    rec_data = {}
    driver_cases = cr.list_cases('driver')
    cases = cr.get_cases('driver')
    for case in cases:
        for key in case.outputs.keys():
            if key not in rec_data:
                rec_data[key] = []
            rec_data[key].append(case[key])
        
    return rec_data