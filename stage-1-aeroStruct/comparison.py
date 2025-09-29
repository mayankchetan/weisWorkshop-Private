
#!/usr/bin/env python3
import os
from weis import weis_main

import numpy as np
from openfast_io import FileTools
import pandas as pd
import matplotlib.pyplot as plt


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


baseline_turb = pd.read_csv("outputs_nonOpti/stage-1-aeroStruct-NonOptimized.csv", index_col=0)
optimized_turb = pd.read_csv("outputs/stage-1-aeroStruct-aero_analysis.csv", index_col=0)

# Creating Cp, Ct, power, thrust, pitch, induction vs WS
fig,ax = plt.subplots(3, 2, figsize=(12, 10),)
fig.suptitle("Turbine Performance Curves", fontsize=16)

ax[0, 0] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                   optimized_turb.loc['rotorse.rp.powercurve.Cp_aero']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Cp',
                  title='Power Coefficient (Cp)', ax=ax[0, 0], label = 'Optimized')

ax[0, 0] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                   baseline_turb.loc['rotorse.rp.powercurve.Cp_aero']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Cp',
                  title='Power Coefficient (Cp)', ax=ax[0, 0], label = 'Baseline')

ax[0, 1] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                   optimized_turb.loc['rotorse.rp.powercurve.Ct_aero']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Ct',
                  title='Thrust Coefficient (Ct)', ax=ax[0, 1], label = 'Optimized')

ax[0, 1] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                   baseline_turb.loc['rotorse.rp.powercurve.Ct_aero']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Ct',
                  title='Thrust Coefficient (Ct)', ax=ax[0, 1], label = 'Baseline')

ax[1, 0] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                     optimized_turb.loc['rotorse.rp.aep.P']['values'],
                    xlabel='Wind Speed (m/s)', ylabel='Power (kW)',
                    title='Turbine Power Output', ax=ax[1, 0], label = 'Optimized')

ax[1, 0] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                     baseline_turb.loc['rotorse.rp.aep.P']['values'],
                    xlabel='Wind Speed (m/s)', ylabel='Power (kW)',
                    title='Turbine Power Output', ax=ax[1, 0], label = 'Baseline')

ax[1, 1] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                     optimized_turb.loc['rotorse.rp.powercurve.T']['values'],
                    xlabel='Wind Speed (m/s)', ylabel='Thrust (kN)',
                    title='Turbine Thrust Output', ax=ax[1, 1], label = 'Optimized')

ax[1, 1] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                   baseline_turb.loc['rotorse.rp.powercurve.T']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Thrust (kN)',
                  title='Turbine Thrust Output', ax=ax[1, 1], label = 'Baseline')

ax[2, 0] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                     optimized_turb.loc['rotorse.rp.powercurve.pitch']['values'],
                    xlabel='Wind Speed (m/s)', ylabel='Pitch Angle (deg)',
                    title='Turbine Pitch Angle', ax=ax[2, 0], label = 'Optimized')

ax[2, 0] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                   baseline_turb.loc['rotorse.rp.powercurve.pitch']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Pitch Angle (deg)',
                  title='Turbine Pitch Angle', ax=ax[2, 0], label = 'Baseline')

ax[2, 1] = plotter(optimized_turb.loc['rotorse.rp.powercurve.V']['values'],
                     optimized_turb.loc['rotorse.rp.powercurve.ax_induct_rotor']['values'],
                    xlabel='Wind Speed (m/s)', ylabel='Induction Factor',
                    title='Turbine Induction Factor', ax=ax[2, 1], label = 'Optimized')

ax[2, 1] = plotter(baseline_turb.loc['rotorse.rp.powercurve.V']['values'],
                   baseline_turb.loc['rotorse.rp.powercurve.ax_induct_rotor']['values'],
                  xlabel='Wind Speed (m/s)', ylabel='Induction Factor',
                  title='Turbine Induction Factor', ax=ax[2, 1], label = 'Baseline')

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.savefig("plots/turbine_performance_curves.png", dpi=300)


# Geomtric plots

fig,ax = plt.subplots(1, 2, figsize=(12, 5),)

ax[0] = plotter(baseline_turb.loc['rotorse.r']['values'],
                baseline_turb.loc['rotorse.chord']['values'],
                xlabel='Span (m)', ylabel='Chord (m)',
                title='Blade Chord Distribution', ax=ax[0], label = 'Baseline')

ax[0] = plotter(optimized_turb.loc['rotorse.r']['values'],
                optimized_turb.loc['rotorse.chord']['values'],
                xlabel='Span (m)', ylabel='Chord (m)',
                title='Blade Chord Distribution', ax=ax[0], label = 'Optimized')

ax[1] = plotter(baseline_turb.loc['rotorse.r']['values'],
                baseline_turb.loc['rotorse.ccblade.theta_in']['values'],
                xlabel='Span (m)', ylabel='Twist (deg)',
                title='Blade Twist Distribution', ax=ax[1], label = 'Baseline')

ax[1] = plotter(optimized_turb.loc['rotorse.r']['values'],
                optimized_turb.loc['rotorse.ccblade.theta_in']['values'],
                xlabel='Span (m)', ylabel='Twist (deg)',
                title='Blade Twist Distribution', ax=ax[1], label = 'Optimized')

plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.savefig("plots/blade_geometry.png", dpi=300)