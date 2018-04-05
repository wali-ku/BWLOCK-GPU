#!/usr/bin/env python
import sys, os, re
import matplotlib
matplotlib.use('Agg')
import numpy as np
import matplotlib.pylab as pl
from matplotlib.backends.backend_pdf import PdfPages
from argparse import ArgumentParser

# Extract data from the given trace file about the virtual runtime and
# throttling duration of memory hog and cpu hog tasks
def parse (trace_file):
    data = {}
    bw_regex = r'^.*\[MONITOR\] Task:\s+([a-z_]+)\s+\|\s+V-Time:\s+([\d]+).*$'

    period_cnt = 0
    period_limit = 10000
    with open (trace_file, 'r') as fdi:
        for line in fdi:
            bw_match = re.match (bw_regex, line)

            if bw_match:
                benchmark = bw_match.group (1)

                if benchmark == 'bw_cpu' or benchmark == 'bw_mem':
                    vruntime  = int (bw_match.group (2), 10)
                    
                    # Check if throttled
                    if 'THROTTLED' in line:
                        data [period_cnt] = [benchmark, vruntime, 1]
                    else:
                        data [period_cnt] = [benchmark, vruntime, 0]
                    period_cnt += 1

                    if period_cnt >= period_limit:
                        break

    # Data aggregation complete
    return data

def plot_data (data):
    # Collect data
    tick_data = {}
    fig_names = {}
    fig_names ['tfs0x'] = 'a'
    fig_names ['tfs1x'] = 'b'
    fig_names ['tfs3x'] = 'c'
    max_vruntime = 0
    for filename in data:
        bw_mem_periods = []
        bw_mem_runtime = []
        bw_cpu_periods = []
        bw_cpu_runtime = []
        start_period = 5000
        start_vruntime = data [filename][start_period][1]
        for period in range (start_period, start_period + 1000):
            data [filename][period][1] = data [filename][period][1] - start_vruntime
            if data [filename][period][0] == 'bw_mem':
                bw_mem_periods.append (period - start_period)
                bw_mem_runtime.append (data [filename][period][1])
            else:
                bw_cpu_periods.append (period - start_period)
                bw_cpu_runtime.append (data [filename][period][1])
        new_max_vruntime = max (max (bw_mem_runtime), max (bw_cpu_runtime))
        max_vruntime = max (max_vruntime, new_max_vruntime)

        tick_data [filename] = {}
        tick_data [filename]['MEM'] = {}
        tick_data [filename]['CPU'] = {}
        tick_data [filename]['MEM']['xticks'] = bw_mem_periods
        tick_data [filename]['MEM']['bars']   = bw_mem_runtime
        tick_data [filename]['CPU']['xticks'] = bw_cpu_periods
        tick_data [filename]['CPU']['bars']   = bw_cpu_runtime
    
    for filename in data:
        # Make the plot for virtual runtime
        fig = pl.figure (figsize = (12, 14))
        pl.bar (tick_data [filename]['MEM']['xticks'], tick_data [filename]['MEM']['bars'],  lw = 0, width = 1, color = 'red', label = 'Memory Intensive Process')
        pl.bar (tick_data [filename]['CPU']['xticks'], tick_data [filename]['CPU']['bars'],  lw = 0, width = 1, color = 'green', label = 'CPU Intensive Process')
        pl.legend (loc = 'upper center', fontsize = 'xx-large')
        pl.grid ()
        pl.xlim (0, 1000)
        pl.ylim (0, max_vruntime)
        pl.yticks ([])
        pl.xlabel ('Periods', fontsize = 'xx-large', fontweight = 'bold')
        pl.ylabel ('Virtual Runtime', fontsize = 'xx-large', fontweight = 'bold')
    
        # Save the plot
        pp = PdfPages ('fig5%s-vruntime.pdf' % (fig_names [filename]))
        pp.savefig (fig)
        pp.close ()
        pl.close ()

        # Make the plot for periods utilized by memory hog and cpu hog processes
        fig = pl.figure (figsize = (12, 14))
        mem_periods = len (tick_data [filename]['MEM']['bars'])
        cpu_periods = len (tick_data [filename]['CPU']['bars'])
        pl.bar ([1], mem_periods, lw = 0, width = 1, color = 'red', label = 'Memory Intensive Process')
        pl.bar ([3], cpu_periods, lw = 0, width = 1, color = 'green', label = 'CPU Intensive Process')
        pl.legend (loc = 'upper center', fontsize = 'xx-large')
        pl.grid ()
        pl.xlim (0, 5)
        pl.ylim (0, 1000)
        pl.xticks ([])
        pl.yticks ([])
        pl.text (1.2, mem_periods + 10, str (mem_periods), size = 'xx-large')
        pl.text (3.2, cpu_periods + 10, str (cpu_periods), size = 'xx-large')
        pl.xlabel ('Process', fontsize = 'xx-large', fontweight = 'bold')
        pl.ylabel ('Periods Utilized', fontsize = 'xx-large', fontweight = 'bold')
    
        # Save the plot
        pp = PdfPages ('fig6%s-vruntime.pdf' % (fig_names [filename]))
        pp.savefig (fig)
        pp.close ()
        pl.close ()


    return

# This is the entry point into this script
def main ():
    parser = ArgumentParser ()
    parser.add_argument ("results_dir", help = "Path to the directory   \
                          containing results for BWLOCK++ (motivation)  \
                          experiment")
    args = parser.parse_args ()

    tfs_factors = [0, 1, 3]
    aggregate_data = {}
    for factor in tfs_factors:
        filename = 'tfs%dx' % (factor)
        trace_file = args.results_dir + '/%s.trace' % (filename)
        aggregate_data [filename] = parse (trace_file)

    plot_data (aggregate_data)

    return

if __name__ == "__main__":
    main ()
