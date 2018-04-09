#!/bin/bash
# This script performs a simple sanity check on the system to confirm whether
# it is in a correct functional state to be used with BWLOCK++

. ./functions.sh
scenario=sanity

# Insert BWLOCK++ kernel module with 64-MBps budget and no TFS
setup_bwlock 1024 0

# Execute best-effort memory bandwidth intensive co-runner on 3 system cores
execute_corunners 3

# Run a real-time task on Core-0 which acquires BWLOCK
echo -e "${YLW}[STATUS] Executing Critical RT-Task for 10 seconds${NCL}"
cp ${bwlock_mod_path}/test/rt_test/critical critical
taskset -c 0 chrt -f 5 ./critical CRIT 0 50 1 &> /dev/null &

# Let the applications run for 10-seconds
sleep 10

# Kill all the background jobs (Including critical task)
stop_corunners

# Extract total system throttle time from BWLOCK++ module
total_throttle_time=`cat /sys/kernel/debug/bwlock/reset_and_show_throttle_time | tr -dc '0-9'`

# Remove kernel module
cleanup_bwlock
rm -f critical

if [ "${total_throttle_time}" != "0" ]; then
	printf "${YLW}[STATUS] Test passed <system was throttled for: %12lld nsec>. System is ready for BWLOCK++${NCL}\n" "${total_throttle_time}"
else
	echo -e "${RED}[ERROR] Test failed. System is not ready for BWLOCK++${NCL}"
fi
