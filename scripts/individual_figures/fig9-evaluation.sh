#!/bin/bash
# Script for generating data and plotting graph of Fig-9 from BWLOCK++ paper

. ./functions.sh
scenario=evaluation

if [ "$1" == "run_the_experiment" ]; then
	setup_bwlock 1024 0
	for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
		name=${parboil_benchmarks[${benchmark_number}]}
		compile=${parboil_compile[${benchmark_number}]}
		dataset=${parboil_datasets[${benchmark_number}]}
		budget=${parboil_budgets[${benchmark_number}]}
	
		echo -e "${YLW}[STATUS] Executing Parboil benchmark with BWLOCK++ | ${name}${NCL}"
		echo ${budget} > /sys/kernel/debug/bwlock/corun_threshold_events
		execute_parboil 3 ${name} ${compile} ${dataset} ${scenario} LOCKED
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

if [ -d results/slowdown ]; then
	cp results/slowdown/* results/${scenario}/.

	# Create the plot
	python graph_scripts/${scenario}.py results/${scenario}/
	mv fig9-${scenario}.pdf figures/.
	echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/fig9-${scenario}.pdf${NCL}"
else
	echo -e "${RED}[ERROR] Please collect data for Fig-7 (slowdown) before running this script${NCL}"
fi
