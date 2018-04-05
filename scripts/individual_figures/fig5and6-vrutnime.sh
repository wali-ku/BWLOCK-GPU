#!/bin/bash
. ./functions.sh

scenario=vruntime

if [ "$1" == "run_the_experiment" ]; then
	setup_bwlock 16384 0
	mkdir -p ${results_path}/${scenario}
	cp ${corun_path}/bandwidth bw_mem
	cp ${corun_path}/bandwidth bw_cpu
	cp ${bwlock_mod_path}/test/rt_test/critical critical
	echo 16384 > /sys/kernel/debug/bwlock/corun_threshold_events
	
	for tfs_factor in 0 1 3; do
		echo -e "${YLW}[STATUS] Collecting data with TFS-${tfs_factor}x${NCL}"
		reset_log
		echo ${tfs_factor} > /sys/kernel/debug/bwlock/tfs_throttle_factor
		taskset -c 0 chrt -f 5 ./critical CRIT 0 50 1 &> /dev/null &
		execute_mixed_corunners 1
		sleep 10
		stop_corunners
		cp /sys/kernel/debug/tracing/trace ${results_path}/${scenario}/tfs${tfs_factor}x.trace
	done
	echo -e "${YLW}[STATUS] Data aggregation complete${NCL}"
	
	rm -f bw_mem bw_cpu critical
	cleanup_bwlock ${scenario}
else
	if [ -d results/${scenario} ]; then
		echo -e "${YLW}[STATUS] Plotting results with existing data${NCL}"
	else
		echo -e "${RED}[ERROR] Must run the experiment before plotting data${NCL}"
		exit 1
	fi
fi

# Create the plot
python graph_scripts/${scenario}.py results/${scenario}/
mv fig*-${scenario}.pdf figures/.
echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/ directory${NCL}"
