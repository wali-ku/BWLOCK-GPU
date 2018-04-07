#!/bin/bash
# Script for generating data and plotting graph of Fig-10 from BWLOCK++ paper

. ./functions.sh
scenario=tfs

cp ${corun_path}/bandwidth bw_mem
cp ${corun_path}/bandwidth bw_cpu

setup_bwlock 1024 0
if [ "$1" == "run_the_experiment" ]; then
	for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
		name=${parboil_benchmarks[${benchmark_number}]}
		compile=${parboil_compile[${benchmark_number}]}
		dataset=${parboil_datasets[${benchmark_number}]}
		budget=${parboil_budgets[${benchmark_number}]}
	
		for tfs_factor in 0 1 3; do
			echo ${budget} > /sys/kernel/debug/bwlock/corun_threshold_events
			echo ${tfs_factor} > /sys/kernel/debug/bwlock/tfs_throttle_factor
			echo -e "${YLW}[STATUS] Executing Parboil benchmark with BWLOCK++ TFS-${tfs_factor}x | ${name}${NCL}"
			execute_parboil_tfs 3 ${name} ${compile} ${dataset} ${scenario} ${tfs_factor}
			echo 1 > /sys/kernel/debug/bwlock/reset_throttle_time
			sleep 1
			cat /sys/kernel/debug/bwlock/system_throttle_time &> results/${scenario}/${name}_tfs${tfs_factor}x.trace
			echo 1 > /sys/kernel/debug/bwlock/reset_throttle_time
			sleep 1
		done
	done
else
	if [ -d results/${scenario} ]; then
		echo -e "${YLW}[STATUS] Plotting results with existing data${NCL}"
	else
		echo -e "${RED}[ERROR] Must run the experiment before plotting data${NCL}"
		exit 1
	fi
fi
cleanup_bwlock
rm -f bw_mem bw_cpu

# Create the plot
python graph_scripts/${scenario}.py results/${scenario}/
mv fig10-${scenario}.pdf figures/.
echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/fig10-${scenario}.pdf${NCL}"
