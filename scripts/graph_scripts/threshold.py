#!/usr/bin/env python
import sys, os, re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as pl
from matplotlib.backends.backend_pdf import PdfPages
from argparse import ArgumentParser

data = {}
def parse (file_name, data_set):

    # Define regular expressions for extracting data of interest
    kernel_regex    = '^\s*Kernel\s+:\s+([0-9\.]+)\s*$'
    compute_regex   = '^\s*Compute\s+:\s+([0-9\.]+)\s*$'
    copy_regex      = '^\s*Copy\s+:\s+([0-9\.]+)\s*$'
    ttime_regex     = '^\s*Timer Wall Time\s*:\s+([0-9\.]+)\s*$'

    with open (file_name, 'r') as fdi:
        data [data_set] = [0, 0, 0, 0, 0]
        for line in fdi:
            kernel_match    = re.match (kernel_regex, line)
            compute_match   = re.match (compute_regex, line)
            copy_match      = re.match (copy_regex, line)
            ttime_match     = re.match (ttime_regex, line)

            if kernel_match:
                kernel_time     = float (kernel_match.group (1))
                data [data_set][0] = kernel_time
            elif compute_match:
                compute_time    = float (compute_match.group (1))
                data [data_set][1] = compute_time
            elif copy_match:
                copy_time       = float (copy_match.group (1))
                data [data_set][2] = copy_time
            elif ttime_match:
                total_time      = float (ttime_match.group (1))
                data [data_set][3] = total_time

    net_time = 0
    for sub_time in data [data_set][:-2]:
        net_time = net_time + sub_time
    data [data_set][4] = net_time

def plot_data (data_sets):
    # Coallate data points
    idt = 4
    try:
        kernel_data     = [((data [key][idt] - data ['Solo'][idt]) * 100.0 / data ['Solo'][idt]) for key in data_sets [:-1]]
    except:
        print "Exception for key : ", key

    # Define kernel ticks
    timer_ticks     = [1 + offset * 2 for offset in xrange (len (data.keys ()) - 1)]

    fig = pl.figure (figsize = (12, 14))

    # Plot bar charts
    # pl.bar (timer_ticks, timer_data, width = 1, color = 'lightgrey', hatch = 'xxx', label = 'Total Time')
    pl.bar (timer_ticks, kernel_data, width = 1, color = 'lightgrey', hatch = 'xx') 

    # Place labels on xticks
    x_ticks = [tick + 0.5 for tick in timer_ticks]
    pl.xticks (x_ticks, data_sets, rotation = 25, fontsize = 'x-large', fontweight = 'bold') 
    pl.yticks (fontsize = 'x-large', fontweight = 'bold')

    # Format axes
    # pl.ylim (0, 300)
    pl.xlim (0, timer_ticks [-1] + 2)

    # Specify label for the axes
    pl.xlabel ('Corun Bandwidth Threshold (MBps)', fontsize = 'xx-large', fontweight = 'bold')
    pl.ylabel ('Percentage Slowdown', fontsize = 'xx-large', fontweight = 'bold')
    # pl.title ('Effect of Allowed Bandwidth Threshold on\nthe execution of Histogram Benchmark (Single Corunner)', fontweight = 'bold')
    pl.grid ()
    
    # Save the figure
    pp = PdfPages ('fig8-threshold.pdf')
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

    # Place the corun stats at the start of parsed data
    filenames	= ['INF', '1024', '512', '256', '128', '64', '32', '16', '8', '4', '2', '1']
    data_sets	= ['Corun'] + filenames [1:]
    
    for plot_number in xrange (len (filenames)):
    	file_path = args.results_dir + '/corun_%smbps.log' % filenames [plot_number]
    	parse (file_path, data_sets [plot_number])
    
    # Place the solo stats at the end of parsed data
    data_sets.append ('Solo')
    parse (args.results_dir + '/solo.log', 'Solo')
    
    id_hash = {}
    id_hash ['Kernel'] = 0
    id_hash ['Copy'] = 2
    id_hash ['Execution'] = 4
    plot_data (data_sets)

    return

if __name__ == "__main__":
    main ()
