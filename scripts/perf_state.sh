#!/bin/sh
# This script displays the state of various configuration options on the TX1.
echo "WARNING - Must Be Run Sudo"
echo "WARNING - Use Only on TX2"

echo "Fan setting"
cat /sys/kernel/debug/tegra_fan/target_pwm

echo "Cores active"
cat /sys/devices/system/cpu/online

echo "Scaling governors (0, 3, 4, 5)"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu5/cpufreq/scaling_governor

echo "CPU available frequencies"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies

echo "CPU cycle frequencies (0, 3, 4, 5)"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
cat /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq

echo "Throttling"
cat /proc/sys/kernel/sched_rt_runtime_us

echo "End Performance States"
