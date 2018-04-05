#!/bin/bash
# This script run the experiment to collect data for plotting the
# corun-threshold plot for histo benchmark (Figure-8 in paper)

. ./functions.sh
scenario=threshold

if [ "$1" == "run_the_experiment" ]; then
	# Threshold for corunning benchmarks in number of LLC miss events
	corun_llc_events=(16384 8192 4096 2048 1024 512 256 128 64 32 16)
	
	setup_bwlock 1024 0
	for threshold in ${corun_llc_events[@]}; do
		corun_bandwidth=$((${threshold} * 64 / 1024))
		echo -e "${YLW}[STATUS] Executing Parboil benchmark (histo) with corun threshold = ${corun_bandwidth} MB/sec${NLC}"
		echo ${threshold} > /sys/kernel/debug/bwlock/corun_threshold_events
		execute_parboil 3 histo cuda large ${scenario} LOCKED
		mv ${results_path}/${scenario}/histo_corun3_locked.log ${results_path}/${scenario}/corun_${corun_bandwidth}mbps.log
	done
	cleanup_bwlock ${scenario}
else
	if [ -d results/${scenario} ]; then
		echo -e "${YLW}[STATUS] Plotting results with existing data${NCL}"
	else
		echo -e "${RED}[ERROR] Must run the experiment before plotting data${NCL}"
		exit 1
	fi
fi

if [ -d results/motivation ]; then
	cp results/motivation/histo_corun3_unlocked.log results/${scenario}/corun_INFmbps.log
	cp results/motivation/histo_corun0_unlocked.log results/${scenario}/solo.log

	# Create the plot
	python graph_scripts/${scenario}.py results/${scenario}/
	mv fig8-${scenario}.pdf figures/.
	echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/fig8-${scenario}.pdf${NCL}"
else
	echo -e "${RED}[ERROR] Please collect data for Fig-1 (motivation) before running this script${NCL}"
fi
