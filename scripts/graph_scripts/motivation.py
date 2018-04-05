#!/usr/bin/env python
import sys, os, re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as pl
from matplotlib.backends.backend_pdf import PdfPages
from argparse import ArgumentParser

# Declare hash for storing parsed data globally
data = {}

def parse_data (file_name, data_set):
    # Define regular expressions for extracting data of interest
    kernel_regex    = '^\s*Kernel\s+:\s+([0-9\.]+)\s*$'
    copy_regex      = '^\s*Copy\s+:\s+([0-9\.]+)\s*$'
    compute_regex   = '^\s*Compute\s+:\s+([0-9\.]+)\s*$'

    data [data_set] = 0
    with open (file_name, 'r') as fdi:
        for line in fdi:
            kernel_match    = re.match (kernel_regex, line)
            copy_match      = re.match (copy_regex, line)
            compute_match   = re.match (compute_regex, line)

            if kernel_match:
                kernel_time                           = float (kernel_match.group (1))
                data [data_set]                       = data [data_set] + kernel_time
            elif copy_match:
                copy_time                             = float (copy_match.group (1))
                data [data_set]                       = data [data_set] + copy_time
            elif compute_match:
                compute_time                          = float (compute_match.group (1))
                data [data_set]                       = data [data_set] + compute_time

    # All done here
    return

def plot_data (data_sets):
    # Coallate data points
    corun_data  = [(data [data_set] / data ['Solo']) for data_set in data_sets [:4]]
    bwlock_data = [(data [data_set] / data ['Solo']) for data_set in data_sets [4:]]

    # Assign ticks to bars
    max_ticks  = [1 + offset * 4 for offset in xrange (len (data_sets [:4]))]
    mean_ticks = [2 + offset * 4 for offset in xrange (len (data_sets [:4]))]

    # Create a figure for saving all the plots
    fig = pl.figure (figsize = (12, 14))
    pl.bar (max_ticks,  corun_data,  width = 1, color = 'lightgrey', hatch = 'xx', label = 'Without BWLOCK++')
    pl.bar (mean_ticks, bwlock_data, width = 1, color = 'lightgrey', hatch = '..', label = 'With BWLOCK++')

    # Place labels on xticks
    x_ticks = [tick for tick in mean_ticks]
    pl.xticks (x_ticks, data_sets [:4], rotation = 0, fontsize = 'xx-large', fontweight = 'bold') 
    pl.yticks (fontsize = 'xx-large', fontweight = 'bold')

    # Specify limits of y-axis
    pl.ylim (0, 3.5)
    pl.xlim (0, mean_ticks [-1] + 2)

    # Specify label for the axes
    pl.ylabel ('Normalized Execution Time', fontsize = 'xx-large', fontweight = 'bold')
    pl.grid ()
    pl.legend (loc = 'upper right', fontsize = 'xx-large')

    # Save the figure
    pp = PdfPages ('fig1-motivation.pdf')
    pp.savefig (fig)
    pp.close ()
    pl.close ()

    # All done here
    return


def execute (results_dir):
    data_sets = ['Corun-3', 'Corun-2', 'Corun-1', 'Solo', 'BWLOCK-3',
                 'BWLOCK-2', 'BWLOCK-1', 'BWLOCK-0']
    file_name = ['corun3_unlocked', 'corun2_unlocked', 'corun1_unlocked',
                 'corun0_unlocked', 'corun3_locked', 'corun2_locked',
                 'corun1_locked', 'corun0_locked']
    
    for execution in xrange (len (data_sets)):
        file_path = results_dir + '/histo_%s.log' % file_name [execution]
        parse_data (file_path, data_sets [execution])
    plot_data (data_sets)
    return

# This is the entry point into this script
def main ():
    parser = ArgumentParser ()
    parser.add_argument ("results_dir", help = "Path to the directory   \
                          containing results for BWLOCK++ (motivation)  \
                          experiment")
    args = parser.parse_args ()
    execute (args.results_dir)
    return

if __name__ == "__main__":
    main ()
