#!/bin/bash
# Script for generating data for Fig-1 of BWLOCK++ paper

. ./functions.sh
scenario=motivation

if [ "$1" == "run_the_experiment" ]; then
	for corunners in `seq 0 3`; do
		echo -e "${GRN}[STATUS] Executing 'histo' benchmark with ${corunners}-corunner(s)${RED}"
		execute_parboil ${corunners} histo cuda large ${scenario} UNLOCKED
	done
	
	setup_bwlock 1024 0
	for corunners in `seq 0 3`; do
		echo -e "${GRN}[STATUS] Executing 'histo' benchmark with ${corunners}-corunners(s) under BWLOCK++${RED}"
		execute_parboil ${corunners} histo cuda large ${scenario} LOCKED
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

# Create the plot
python graph_scripts/${scenario}.py results/${scenario}/
mv fig1-${scenario}.pdf figures/.
echo -e "${YLW}[STATUS] Execution complete. The plot can now be seen here: figures/fig1-${scenario}.pdf${NCL}"
