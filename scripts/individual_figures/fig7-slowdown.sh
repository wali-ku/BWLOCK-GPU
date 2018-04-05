#!/bin/bash
# Script for generating data and plotting graph of Fig-7 from BWLOCK++ paper

. ./functions.sh
scenario=slowdown

if [ "$1" == "run_the_experiment" ]; then
	# Collect data for parboil benchmark slowdown experiment
	for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
		name=${parboil_benchmarks[${benchmark_number}]}
		compile=${parboil_compile[${benchmark_number}]}
		dataset=${parboil_datasets[${benchmark_number}]}
	
		echo -e "${YLW}[STATUS] Executing Parboil benchmark without corunners | ${name}${NCL}"
		execute_parboil 0 ${name} ${compile} ${dataset} ${scenario} UNLOCKED
	
		echo -e "${YLW}[STATUS] Executing Parboil benchmark with 3-corunners  | ${name}${NCL}"
		execute_parboil 3 ${name} ${compile} ${dataset} ${scenario} UNLOCKED
	done
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
mv fig7-${scenario}.pdf figures/.
echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/fig7-${scenario}.pdf${NCL}"
