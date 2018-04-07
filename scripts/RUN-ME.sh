#!/bin/bash

# Here are all the figures we need to plot and the data we need to collect for
# plotting these figures:
# Fig-1
# Histo benchmark with and without BWLOCK++ with 0, 1, 2 and 3 corunners
#
# Fig-5 and Fig-6
# Virtual runtime experiments with synthetic tasks under BWLOCK++ with TFS: 0,
# 1 and 3
#
# Fig-7
# Execution statistics of selected parboil benchmarks under solo and under 3
# corunners
#
# Fig-8
# Execution statistics of histo benchmark with 3 corunners under BWLOCK++ with
# different corun thresholds
#
# Fig-9
# Execution statistics of selected parboil benchmarks under 3 corunners with
# BWLOCK++ (@NOTE: requires all data from Fig-7 experiment)
#
# Fig-10
# Trace log for selected parboil benchmarks under 3 corunners with BWLOCK++
# under TFS-0, 1 and 3 factors
#
###### Classification
# Since data for a couple of these experiments can be reused in other
# experiments, we will execute them in a specific order so as to facilitate
# data reuse and hence reduce data aggregation time
#
# Experiments not requiring BWLOCK++
# * [STEP-1] Fig-1: Run histo with 1 and 2 corunners
# * [STEP-2] Fig-7
#
# Experiment requiring BWLOCK++
# * [STEP-3] Fig-1: Run histo with 0, 1, 2 corunners
# * [STEP-4] Fig-5 and Fig-6
# * [STEP-5] Fig-8
# * [STEP-6] Fig-9: Run selected parboil benchmarks with 3-corunners
# * [STEP-7] Fig-10
#
# [STEP-8] Data categorization and plotting
#
# Author	: Waqar Ali (wali@ku.edu)

. ./functions.sh
scenario=raw_data

# Create directory for saving figures
mkdir -p figures
cp ${corun_path}/bandwidth bw_mem
cp ${corun_path}/bandwidth bw_cpu
cp ${bwlock_mod_path}/test/rt_test/critical critical

# Begin data aggregation
echo -e "${CYN}***** STEP [1/8]${NCL}"
for corunners in 1 2; do
	echo -e "${YLW}[STATUS] Executing 'histo' benchmark with ${corunners}-corunner(s)${RED}"
	execute_parboil ${corunners} histo cuda large ${scenario} UNLOCKED
done

# Collect data for parboil benchmark slowdown experiment
echo -e "${CYN}***** STEP [2/8]${NCL}"
for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
	name=${parboil_benchmarks[${benchmark_number}]}
	compile=${parboil_compile[${benchmark_number}]}
	dataset=${parboil_datasets[${benchmark_number}]}

	echo -e "${YLW}[STATUS] Executing Parboil benchmark without corunners | ${name}${NCL}"
	execute_parboil 0 ${name} ${compile} ${dataset} ${scenario} UNLOCKED

	echo -e "${YLW}[STATUS] Executing Parboil benchmark with 3-corunners  | ${name}${NCL}"
	execute_parboil 3 ${name} ${compile} ${dataset} ${scenario} UNLOCKED
done

# Setup BWLOCK++
echo -e "${CYN}***** STEP [3/8]${NCL}"
setup_bwlock 1024 0

for corunners in 0 1 2 3; do
	echo -e "${YLW}[STATUS] Executing 'histo' benchmark with ${corunners}-corunners(s) under BWLOCK++${RED}"
	execute_parboil ${corunners} histo cuda large ${scenario} LOCKED
done

# Collect data for Fig-5 and Fig-6 with synthetic benchmarks
echo -e "${CYN}***** STEP [4/8]${NCL}"
echo 16384 > /sys/kernel/debug/bwlock/corun_threshold_events
for tfs_factor in 0 1 3; do
	echo -e "${YLW}[STATUS] Collecting data using synthetic taskset with TFS-${tfs_factor}x${NCL}"
	reset_log
	echo ${tfs_factor} > /sys/kernel/debug/bwlock/tfs_throttle_factor
	taskset -c 0 chrt -f 5 ./critical CRIT 0 50 1 &> /dev/null &
	execute_mixed_corunners 1
	sleep 10
	stop_corunners
	cp /sys/kernel/debug/tracing/trace ${results_path}/${scenario}/tfs${tfs_factor}x.trace
done

# Collect data for Fig-8
echo -e "${CYN}***** STEP [5/8]${NCL}"

# Threshold for corunning benchmarks in number of LLC miss events
corun_llc_events=(16384 8192 4096 2048 1024 512 256 128 64 32 16)

for threshold in ${corun_llc_events[@]}; do
	corun_bandwidth=$((${threshold} * 64 / 1024))
	echo -e "${YLW}[STATUS] Executing Parboil benchmark (histo) with corun threshold = ${corun_bandwidth} MB/sec${NLC}"
	echo ${threshold} > /sys/kernel/debug/bwlock/corun_threshold_events
	execute_parboil 3 histo cuda large ${scenario} LOCKED
	mv ${results_path}/${scenario}/histo_corun3_locked.log ${results_path}/${scenario}/corun_${corun_bandwidth}mbps.log
done

# Collect data for Fig-9
echo -e "${CYN}***** STEP [6/8]${NCL}"
for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
	name=${parboil_benchmarks[${benchmark_number}]}
	compile=${parboil_compile[${benchmark_number}]}
	dataset=${parboil_datasets[${benchmark_number}]}
	budget=${parboil_budgets[${benchmark_number}]}

	echo -e "${YLW}[STATUS] Executing Parboil benchmark with BWLOCK++ | ${name}${NCL}"
	echo ${budget} > /sys/kernel/debug/bwlock/corun_threshold_events
	execute_parboil 3 ${name} ${compile} ${dataset} ${scenario} LOCKED
done

# Collect data for Fig-10
echo -e "${CYN}***** STEP [7/8]${NCL}"
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

# Cleanup. Re-arrange data and plot results
echo -e "${CYN}***** STEP [8/8]${NCL}"
rm -f bw_mem bw_cpu critical
cleanup_bwlock

# Gather data for Fig-1 (motivation)
mkdir -p results/motivation
cp results/${scenario}/histo_corun*_*locked.log results/motivation/.

# Gather data for Fig-5 and Fig-6 (TFS Demo with synthetic tasks)
mkdir -p results/vruntime
cp results/${scenario}/tfs*x.trace results/vruntime/.

# Gather data for Fig-7 (Slowdown of Parboil benchmarks)
mkdir -p results/slowdown
cp results/${scenario}/*_corun*_unlocked.log results/slowdown/.

# Gather data for Fig-8 (Threshold selection for histo benchmark)
mkdir -p results/threshold
cp results/${scenario}/corun_*mbps.log results/threshold/.
cp results/${scenario}/histo_corun3_unlocked.log results/threshold/corun_INFmbps.log
cp results/${scenario}/histo_corun0_locked.log results/threshold/solo.log

# Gather data for Fig-9 (Evaluation)
mkdir -p results/evaluation
cp results/${scenario}/*_corun*_*locked.log results/evaluation/.

# Gather data for Fig-10 (TFS Evaluation)
mkdir -p results/tfs
cp results/${scenario}/*_tfs*x.trace results/tfs/.

# Plot graphs
figures=('motivation' 'vruntime' 'slowdown' 'threshold' 'evaluation' 'tfs')
for figure in ${figures[@]}; do 
	python graph_scripts/${figure}.py results/${figure}/
done

# All done
mv *.pdf figures/.
echo -e "${CYN}***** Execution complete. Plots can now be seen in figures/ directory${NCL}"
