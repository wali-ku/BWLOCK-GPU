#!/usr/bin/env pythop
import sys, os, re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as pl
from matplotlib.backends.backend_pdf import PdfPages
from argparse import ArgumentParser

# Declare hash for storing parsed data globally
data = {}

def parse_parboil (file_name, benchmark, data_set):
    # Define regular expressions for extracting data of interest
    kernel_regex    = '^\s*Kernel\s+:\s+([0-9\.]+)\s*$'
    copy_regex      = '^\s*Copy\s+:\s+([0-9\.]+)\s*$'
    compute_regex   = '^\s*Compute\s+:\s+([0-9\.]+)\s*$'

    with open (file_name, 'r') as fdi:
        data [benchmark][data_set] = {}
        for line in fdi:
            kernel_match    = re.match (kernel_regex, line)
            copy_match      = re.match (copy_regex, line)
            compute_match   = re.match (compute_regex, line)

            if kernel_match:
                kernel_time                           = float (kernel_match.group (1))
                data [benchmark][data_set]['Kernel']  = kernel_time
            elif copy_match:
                copy_time                             = float (copy_match.group (1))
                data [benchmark][data_set]['Copy']    = copy_time
            elif compute_match:
                compute_time                          = float (compute_match.group (1))
                data [benchmark][data_set]['Compute'] = compute_time

    if 'Compute' not in data [benchmark][data_set]:
        data [benchmark][data_set]['Compute'] = 0

    if 'Copy' not in data [benchmark][data_set]:
        data [benchmark][data_set]['Copy'] = 0

    data [benchmark][data_set]['Net'] = data [benchmark][data_set]['Kernel'] + \
                                        data [benchmark][data_set]['Copy'] +   \
                                        data [benchmark][data_set]['Compute']

    # All done here
    return

def plot_data (benchmarks):
    # Coallate data points
    corun_slowdown_data = [(((data [key]['Corun']['Net']   / data [key]['Solo']['Net'] - 1)) * 100) for key in benchmarks]
    corun_ticks         = [1 + offset * 2 for offset in xrange (len (data.keys ()))]

    # Create a figure for saving all the plots
    fig = pl.figure (figsize = (12, 14))
    pl.bar (corun_ticks, corun_slowdown_data, width = 1, color = 'lightgrey', hatch = 'xx')

    # Place labels on xticks
    x_ticks = [tick + 0.5 for tick in corun_ticks]
    pl.xticks (x_ticks, benchmarks, rotation = 0, fontsize = 'xx-large', fontweight = 'bold') 
    pl.yticks (fontsize = 'x-large', fontweight = 'bold')

    # Specify limits of y-axis
    pl.ylim (0, 250)
    pl.xlim (0, corun_ticks [-1] + 2)

    # Specify label for the axes
    pl.ylabel ('Percentage Slowdown', fontsize = 'xx-large', fontweight = 'bold')
    pl.grid ()

    # Save the figure
    pp = PdfPages ('fig7-slowdown.pdf')
    pp.savefig (fig)
    pp.close ()
    pl.close ()

    # All done here
    return

def analyze_parboil_benchmark (benchmark, results_dir):
    # Declare the data-sets we want to analyze
    datasets = ['Corun', 'Solo']
    filename = ['corun3_unlocked', 'corun0_unlocked']
    data [benchmark] = {}

    for execution in xrange (len (datasets)):
        filepath = results_dir + '/%s_%s.log' % (benchmark, filename [execution])
        parse_parboil (filepath, benchmark, datasets [execution])

    # All done here
    return

# This is the entry point into this script
def main ():
    parser = ArgumentParser ()
    parser.add_argument ("results_dir", help = "Path to the directory   \
                          containing results for BWLOCK++ (motivation)  \
                          experiment")
    args = parser.parse_args ()
    # Declare the names of benchmarks we want to analyze
    benchmarks = ['histo', 'lbm', 'stencil', 'sad', 'spmv', 'bfs']
    
    for benchmark in benchmarks:
        analyze_parboil_benchmark (benchmark, args.results_dir)

    # Plot the parsed data
    ordered_benchmarks = ['histo', 'sad', 'bfs', 'spmv', 'stencil', 'lbm']
    plot_data (ordered_benchmarks)

    return

if __name__ == "__main__":
    main ()
