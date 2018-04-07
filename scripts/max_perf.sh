#!/bin/sh
# This script manually sets the TX2's GPU and memory clock rates to a high
# value, disables frequency scaling, puts the machine in "performance" mode,
# and turns on the fan.
#
# ACKNOWLEDGMENT
#	This script has been adapted from:
#	https://github.com/yalue/cuda_scheduling_examiner_mirror/blob/master/scripts/TX-max_perf.sh
echo "WARNING - Must Be Run Sudo"
echo "WARNING - Use Only on TX2"

./jetson_clocks.sh
service lightdm stop

# Turn on fan for safety"
echo 255 > /sys/kernel/debug/tegra_fan/target_pwm

for core in 0 1 2 3 4 5; do
	if [ "${core}" != "0" ]; then
		echo 1 > /sys/devices/system/cpu/cpu$core/online
		sleep 2
	fi
	echo performance > /sys/devices/system/cpu/cpu$core/cpufreq/scaling_governor
	cat /sys/devices/system/cpu/cpu$core/cpufreq/scaling_max_freq > /sys/devices/system/cpu/cpu$core/cpufreq/scaling_min_freq
done

echo -1 >/proc/sys/kernel/sched_rt_runtime_us

echo "Max Performance Settings Done"
