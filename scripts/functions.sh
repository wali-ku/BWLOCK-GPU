# Utility functions for BWLOCK++ evaluation
root_path=/home/nvidia/BWLOCK-GPU
corun_path=${root_path}/benchmarks/IsolBench/bench
parboil_path=${root_path}/benchmarks/parboil
results_path=${root_path}/scripts/results
bwlock_mod_path=${root_path}/kernel_module
dynamic_linker_path=${root_path}/dynamic_linker
parboil_benchmarks=(	'bfs'		'lbm'		'sad'		'spmv'		'stencil'	'histo'	)
parboil_compile=(	'cuda_base'	'cuda'		'cuda'		'cuda'		'cuda'		'cuda'	)
parboil_datasets=(	'1M' 		'long' 		'large' 	'large' 	'default'	'large' )
parboil_budgets=(	 512 		 256 		 1024 		 1024 		 1024		 1024 	)

# Declare colors for pretty output
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[0;36m'
NCL='\033[0m'

# Flush trace_printk buffer
reset_log () {
	echo function > /sys/kernel/debug/tracing/current_tracer
	echo nop > /sys/kernel/debug/tracing/current_tracer
}

# Build the selected parboil benchmarks
build_parboil () {
	pushd . &> /dev/null
	cd ${parboil_path}
	for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
		name=${parboil_benchmarks[${benchmark_number}]}
		compile=${parboil_compile[${benchmark_number}]}
		echo -e "${GRN}[STATUS] Compiling Parboil | ${name}${NCL}"
		./parboil compile ${name} ${compile} &> /dev/null

		if [ ! -f benchmarks/${name}/build/*/${name} ]; then
			echo -e "${RED}[ERROR] Failed to compile ${name} from Parboil suite${NCL}"
		fi
	done
	popd &> /dev/null
}

# Build BWLOCK++ kernel module
build_bwlock_mod () {
	pushd . &> /dev/null
	cd ${bwlock_mod_path}
	echo -e "${GRN}[STATUS] Building BWLOCK++ kernel module${NCL}"
	make &> /dev/null

	if [ ! -f exe/bwlockmod.ko ]; then
		echo -e "${RED}[ERROR] Failed to compile BWLOCK++ kernel module${NCL}"
	fi
	popd &> /dev/null
}

# Build test RT-task
build_rt_task () {
	pushd . &> /dev/null
	cd ${bwlock_mod_path}/test/rt_test/
	echo -e "${GRN}[STATUS] Building RT-Task${NCL}"
	gcc task.c -o critical &> /dev/null

	if [ ! -f critical ]; then
		echo -e "${RED}[ERROR] Failed to build RT-Task${NCL}"
	fi
	popd &> /dev/null
}

# Build shared-library for intercepting CUDA runtime library calls
build_cuda_hooks () {
	pushd . &> /dev/null
	echo -e "${GRN}[STATUS] Building shared-library for intercepting CUDA calls${NCL}"
	cd ${dynamic_linker_path}
	make &> /dev/null

	if [ ! -f custom_cuda.so ]; then
		echo -e "${RED}[ERROR] Failed to compile shared-library for intercepting CUDA calls${NCL}"
	fi
	popd &> /dev/null
}

# Build bandwidth benchmark from IsolBench
build_isolbench () {
	pushd . &> /dev/null
	cd ${corun_path}
	echo -e "${GRN}[STATUS] Building BANDWIDTH benchmark from IsolBench${NCL}"
	make bandwidth &> /dev/null

	if [ ! -f bandwidth ]; then
		echo -e "${RED}[ERROR] Failed to build BANDWIDTH benchmark${NCL}"
	fi
	popd &> /dev/null
}

# Clean the selected parboil benchmarks
clean_parboil () {
	pushd . &> /dev/null
	cd ${parboil_path}
	for benchmark_number in `seq 0 $((${#parboil_benchmarks[@]} - 1))`; do
		name=${parboil_benchmarks[${benchmark_number}]}
		compile=${parboil_compile[${benchmark_number}]}
		echo -e "${GRN}[STATUS] Cleaning Parboil | ${name}${NCL}"
		./parboil clean ${name} &> /dev/null
	done
	popd &> /dev/null
}

# Clean BWLOCK++ kernel module
clean_bwlock_mod () {
	pushd . &> /dev/null
	cd ${bwlock_mod_path}
	echo -e "${GRN}[STATUS] Cleaning BWLOCK++ kernel module${NCL}"
	make clean &> /dev/null
	popd &> /dev/null
}

# Clean RT-Task
clean_rt_task () {
	pushd . &> /dev/null
	cd ${bwlock_mod_path}/test/rt_test
	echo -e "${GRN}[STATUS] Cleaning RT-Task${NCL}"
	rm -f critical &> /dev/null
	popd &> /dev/null
}

# Clean the shared-library for intercepting CUDA calls
clean_cuda_hooks () {
	pushd . &> /dev/null
	cd ${dynamic_linker_path}
	echo -e "${GRN}[STATUS] Cleaning CUDA shared-library${NCL}"
	make clean &> /dev/null
	popd &> /dev/null
}

# Clean bandwidth benchmark from IsolBench
clean_isolbench () {
	pushd . &> /dev/null
	cd ${corun_path}
	echo -e "${GRN}[STATUS] Cleaning IsolBench${NCL}"
	make clean &> /dev/null
	popd &> /dev/null
}

# Execute specified number of BANDWIDTH corunners on Core-3 to Core-5
# $1 : Number of corunners to execute
execute_corunners () {
	if [ $1 -gt 0 ]; then
		pushd . &> /dev/null
		cd ${corun_path}
		core_limit=$(($1 + 2))
		if [ "$1" == "1" ]; then
			echo -e "${GRN}[STATUS] Starting ${1}-'bandwidth' co-runner on Core-3${RED}"
		else
			echo -e "${GRN}[STATUS] Starting ${1}-'bandwidth' co-runners on Core-3 to Core-${core_limit}${RED}"
		fi
		for core in `seq 3 ${core_limit}`; do
			./bandwidth -c ${core} -t 10000 -m 4096 -a write &> /dev/null&
		done
		sleep 2
		popd &> /dev/null
	fi
}

# Execute specified number of BANDWIDTH corunners on Core-3 to Core-5
# Each core executes two instanes of BANDWIDTH, one of which is configured to
# stress memory and the other is configured to stress CPU
# $1 : Number of corunners to execute
execute_mixed_corunners () {
	if [ $1 -gt 0 ]; then
		core_limit=$(($1 + 2))
		if [ "$1" == "1" ]; then
			echo -e "${GRN}[STATUS] Starting $((${1} * 2))-'bandwidth' co-runner on Core-3${RED}"
		else
			echo -e "${GRN}[STATUS] Starting $((${1} * 2))-'bandwidth' co-runners on Core-3 to Core-${core_limit}${RED}"
		fi
		for core in `seq 3 ${core_limit}`; do
			./bw_mem -c ${core} -t 10000 -m 4096 -a write &> /dev/null&
			./bw_cpu -c ${core} -t 10000 -m 16 &> /dev/null&
		done
		sleep 2
	fi
}

# Kill all BANDWIDTH corunners
stop_corunners () {
	echo -e "${GRN}[STATUS] Stopping 'bandwidth' co-runner(s) if needed${NCL}"
	kill $(jobs -rp) &> /dev/null
	wait $(jobs -rp) &> /dev/null
}

# Insert bandwidth lock kernel module and set the corun threshold and TFS factor
# It is ASSUMED that the kernel module has already been built
# $1 : Corun threshold in number of cache-miss events
# $2 : TFS throttle factor
setup_bwlock () {
	pushd . &> /dev/null
	reset_log
	echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb;
	cd ${bwlock_mod_path}
	insmod exe/bwlockmod.ko &> /dev/null
	mbps=$(($1 * 64 / 1024))
	echo -e "${GRN}[STATUS] Setting up BWLOCK++ with ${mbps}-MBPS corun threshold and throttle factor = ${2}$RED"
	echo $1 > /sys/kernel/debug/bwlock/corun_threshold_events
	echo $2 > /sys/kernel/debug/bwlock/tfs_throttle_factor
	sleep 2
	popd &> /dev/null
}

# Remove bandwidth lock kernel module. Copy over the trace data and reset trace
cleanup_bwlock () {
	rmmod bwlockmod &> /dev/null
	reset_log
	sleep 2
}

# Execute the specified parboil benchmark with the given parameters
# $1 : Number of corunners
# $2 : Benchmark name
# $3 : Build type (CUDA or CUDA_BASE)
# $4 : Dataset
# $5 : Scenario
# $6 : Execute with lock if specified
execute_parboil () {
	mkdir -p ${results_path}/$5
	execute_corunners $1

	pushd . &> /dev/null
	cd ${parboil_path}
	if [ "$6" == "LOCKED" ]; then
		LD_PRELOAD=${dynamic_linker_path}/custom_cuda.so chrt -f 5 taskset -c 0 ./parboil run $2 $3 $4 &> ${results_path}/$5/${2}_corun${1}_locked.log
	else
		chrt -f 5 taskset -c 0 ./parboil run $2 $3 $4 &> ${results_path}/$5/${2}_corun${1}_unlocked.log
	fi
	popd &> /dev/null
	stop_corunners
}

# Execute the specified parboil benchmark with the given parameters under TFS
# $1 : Number of corunners
# $2 : Benchmark name
# $3 : Build type (CUDA or CUDA_BASE)
# $4 : Dataset
# $5 : Scenario
# $6 : TFS throttle factor
execute_parboil_tfs () {
	mkdir -p ${results_path}/$5
	execute_mixed_corunners $1

	pushd . &> /dev/null
	cd ${parboil_path}
	echo $6 > /sys/kernel/debug/bwlock/tfs_throttle_factor
	reset_log
	LD_PRELOAD=${dynamic_linker_path}/custom_cuda.so chrt -f 5 taskset -c 0 ./parboil run $2 $3 $4 &> ${results_path}/$5/${2}_corun${1}_tfs${6}x.log
	popd &> /dev/null
	stop_corunners
}
