#!/usr/bin/env python
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
    try:
        corun_kernel_data   = [(data [key]['Corun']['Kernel']    / data [key]['Solo']['Net']) for key in benchmarks]
        auto_kernel_data    = [(data [key]['Auto']['Kernel']     / data [key]['Solo']['Net']) for key in benchmarks]
        solo_kernel_data    = [(data [key]['Solo']['Kernel']     / data [key]['Solo']['Net']) for key in benchmarks]
        corun_copy_data     = [(data [key]['Corun']['Copy']      / data [key]['Solo']['Net']) for key in benchmarks]
        auto_copy_data      = [(data [key]['Auto']['Copy']       / data [key]['Solo']['Net']) for key in benchmarks]
        solo_copy_data      = [(data [key]['Solo']['Copy']       / data [key]['Solo']['Net']) for key in benchmarks]
        corun_compute_data  = [(data [key]['Corun']['Compute']   / data [key]['Solo']['Net']) for key in benchmarks]
        auto_compute_data   = [(data [key]['Auto']['Compute']    / data [key]['Solo']['Net']) for key in benchmarks]
        solo_compute_data   = [(data [key]['Solo']['Compute']    / data [key]['Solo']['Net']) for key in benchmarks]

        corun_net_data      = [(data [key]['Corun']['Net']    / data [key]['Solo']['Net']) for key in benchmarks]
        auto_net_data       = [(data [key]['Auto']['Net']     / data [key]['Solo']['Net']) for key in benchmarks]
        solo_net_data       = [(data [key]['Solo']['Net']     / data [key]['Solo']['Net']) for key in benchmarks]
    except:
        print "Exception for key : ", key

    # Define kernel ticks
    corun_ticks     = [1 + offset * 5 for offset in xrange (len (data.keys ()))]
    auto_ticks      = [tick + 1 for tick in corun_ticks]
    solo_ticks      = [tick + 2 for tick in corun_ticks]

    # Create a figure for saving all the plots
    fig = pl.figure (figsize = (20, 9))

    # Plot bar charts
    if 0:
        pl.bar (corun_ticks,    corun_kernel_data,      width = 1, color = 'white', hatch = '..', label = '%-14s (Kernel)' % 'Corun-3')
        pl.bar (auto_ticks,     auto_kernel_data,       width = 1, color = 'white', hatch = 'xx', label = '%-8s (Kernel)' % 'BWLOCK++')
        pl.bar (solo_ticks,     solo_kernel_data,       width = 1, color = 'white', hatch = '**', label = '%-17s (Kernel)' % 'Solo')
        pl.bar (corun_ticks,    corun_copy_data,        width = 1, color = 'lightgrey',      hatch = '..', bottom = corun_kernel_data, label = '%-14s (Copy)' % 'Corun-3')
        pl.bar (auto_ticks,     auto_copy_data,         width = 1, color = 'lightgrey',      hatch = 'xx', bottom = auto_kernel_data,  label = '%-8s (Copy)' % 'BWLOCK++')
        pl.bar (solo_ticks,     solo_copy_data,         width = 1, color = 'lightgrey',      hatch = '**', bottom = solo_kernel_data,  label = '%-17s (Copy)' % 'Solo')
        pl.bar (corun_ticks,    corun_compute_data,     width = 1, color = 'dimgray',  hatch = '..', bottom = [corun_kernel_data [x] + corun_copy_data [x] for x in xrange (len (corun_kernel_data))], label = '%-14s (Compute)' % 'Corun-3')
        pl.bar (auto_ticks,     auto_compute_data,      width = 1, color = 'dimgray',  hatch = 'xx', bottom = [auto_kernel_data [x] + auto_copy_data [x] for x in xrange (len (auto_kernel_data))],    label = '%-8s (Compute)' % 'BWLOCK++')
        pl.bar (solo_ticks,     solo_compute_data,      width = 1, color = 'dimgray',  hatch = '**', bottom = [solo_kernel_data [x] + solo_copy_data [x] for x in xrange (len (solo_kernel_data))],    label = '%-17s (Compute)' % 'Solo')

    pl.bar (corun_ticks,    corun_net_data,     width = 1, color = 'lightgrey',  hatch = '..', label = 'Corun')
    pl.bar (auto_ticks,     auto_net_data,      width = 1, color = 'lightgrey',  hatch = 'xx', label = 'BW-Locked-Auto')
    pl.bar (solo_ticks,     solo_net_data,      width = 1, color = 'lightgrey',  hatch = '**', label = 'Solo')
    pl.plot ([0, solo_ticks [-1] + 2], [1.0, 1.0], 'k--', lw = 1.25)

    # Place labels on xticks
    x_ticks = [tick + 0.5 for tick in auto_ticks]
    pl.xticks (x_ticks, benchmarks, rotation = 0, fontsize = 'xx-large', fontweight = 'bold') 
    pl.yticks (fontsize = 'x-large', fontweight = 'bold')

    # Specify limits of y-axis
    pl.ylim (0, 2.5)
    pl.xlim (0, solo_ticks [-1] + 2)

    # Specify label for the axes
    pl.ylabel ('Normalized Execution Time', fontsize = 'xx-large', fontweight = 'bold')

    # Place legend and grid on the plot
    pl.legend (fontsize = 'xx-large', ncol = 3, loc = 'upper right')
    pl.grid ()

    pl.annotate ('Up-to %.1fX' % (corun_kernel_data [0] + corun_copy_data [0] + corun_compute_data [0]), \
                  xy = (1.5, 2.45), xytext = (1.5, 2.25), fontweight = 'bold', fontsize = 'large',       \
                  arrowprops = dict (facecolor = 'black', shrink = 0.05))
    pl.annotate ('Up-to %.1fX' % (corun_kernel_data [1] + corun_copy_data [1] + corun_compute_data [1]), \
                  xy = (corun_ticks [1] + 0.5, 2.45), xytext = (corun_ticks [1] + 0.5, 2.25),            \
                  fontweight = 'bold', fontsize = 'large', arrowprops = dict (facecolor = 'black', shrink = 0.05))
    #pl.annotate ('Up-to %.1fX' % (corun_kernel_data [2] + corun_copy_data [2] + corun_compute_data [2]), \
    #              xy = (corun_ticks [2] + 0.5, 1.95), xytext = (corun_ticks [2] + 0.5, 1.75),            \
    #              fontweight = 'bold', fontsize = 'large', arrowprops = dict (facecolor = 'black', shrink = 0.05))

    # Save the figure
    pp = PdfPages ('fig9-evaluation.pdf')
    pp.savefig (fig)
    pp.close ()
    pl.close ()

    # All done here
    return

def analyze_parboil_benchmark (benchmark, results_dir):
    # Declare the data-sets we want to analyze
    datasets = ['Corun', 'Auto', 'Solo']
    filename = [(3, 'unlocked'), (3, 'locked'), (0, 'unlocked')]
    data [benchmark] = {}

    for execution in xrange (len (datasets)):
        filepath = results_dir + '/%s_corun%d_%s.log' % (benchmark, filename [execution][0], filename [execution][1])
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
