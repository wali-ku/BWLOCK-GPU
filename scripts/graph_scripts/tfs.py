#!/usr/bin/env python
import sys, os, re
import matplotlib
matplotlib.use('Agg')
import numpy as np
import matplotlib.pylab as pl
from matplotlib.backends.backend_pdf import PdfPages
from argparse import ArgumentParser

# Declare global hash for storing parsed data
data = {}

# Create key-value pairs for desired datasets
datasets = {}
datasets ['CFS']   = "tfs0x.trace" 
datasets ['TFS-1'] = "tfs1x.trace" 
datasets ['TFS-3'] = "tfs3x.trace" 

def parse (benchmark, results_dir):
    # Initialize the hash for the target benchmark
    data [benchmark] = {}

    for key in datasets.keys ():
        # Create the filename for the dataset to be analyzed
        filename = results_dir + '/%s_%s' % (benchmark, datasets [key])
    
        # Parse the file and extract the desired data
        with open (filename, 'r') as fdi:
            for line in fdi:
                data [benchmark][key] = float (line)
                break

    # All done here
    return

def plot_data (benchmarks):
    # Collate data points for all the series
    cfs_data    = [1                                                   for benchmark in benchmarks]
    tfs1_data   = [data [benchmark]['TFS-1'] / data [benchmark]['CFS'] for benchmark in benchmarks]
    tfs3_data   = [data [benchmark]['TFS-3'] / data [benchmark]['CFS'] for benchmark in benchmarks]

    mean_tfs1x  = np.mean ([1 - x for x in tfs1_data])
    mean_tfs3x  = np.mean ([1 - x for x in tfs3_data])

    # print "[MEAN] TFS-1X : %.3f | TFS-3X : %.3f" % (mean_tfs1x, mean_tfs3x)
    # print max ([1 - x for x in tfs3_data])

    # Create x-axis ticks for each series
    cfs_ticks   = [1 + x * 4 for x in xrange (len (benchmarks))]
    tfs1_ticks  = [2 + x * 4 for x in xrange (len (benchmarks))]
    tfs3_ticks  = [3 + x * 4 for x in xrange (len (benchmarks))]

    # Create a figure to save the plots
    fig = pl.figure (figsize = (20, 10))

    # Create bar chart for each data series
    pl.bar (cfs_ticks,  cfs_data,  width = 1, color = 'lightgrey', hatch = '..', label = 'CFS')
    pl.bar (tfs1_ticks, tfs1_data, width = 1, color = 'lightgrey', hatch = 'xx', label = 'TFS-1')
    pl.bar (tfs3_ticks, tfs3_data, width = 1, color = 'lightgrey', hatch = '**', label = 'TFS-3')
    pl.plot ([0, tfs3_ticks [-1] + 2], [1.0, 1.0], 'k--', lw = 1.25)

    # Place a grid on the plot and display legend
    pl.legend (loc = 'upper center', fontsize = 'xx-large', ncol = 3)
    pl.grid ()

    # Format the axes
    xticks = [tick + 0.5 for tick in tfs1_ticks]
    pl.xticks (xticks, benchmarks, fontsize = 'xx-large', fontweight = 'bold')
    pl.yticks (fontsize = 'x-large', fontweight = 'bold')
    pl.ylabel ('Normalized System Throttle Time', fontsize = 'xx-large', fontweight = 'bold')
    pl.xlim (0, tfs3_ticks [-1] + 2)
    pl.ylim (0, 1.15)

    # Save the figure
    pp = PdfPages ('fig10-tfs.pdf')
    pp.savefig (fig)
    pp.close ()
    pl.close ()

    # All done here
    return

# This is the entry point into this script
def main ():
    parser = ArgumentParser ()
    parser.add_argument ("results_dir", help = "Path to the directory   \
                          containing results for BWLOCK++ (motivation)  \
                          experiment")
    args = parser.parse_args ()

    # Declare the name of benchmarks we want to analyze
    benchmarks = ['histo', 'sad', 'bfs', 'spmv', 'stencil', 'lbm']
    
    for benchmark in benchmarks:
        parse (benchmark, args.results_dir)
    
    # Plot the parsed data
    plot_data (benchmarks)


    return

if __name__ == "__main__":
    main ()
