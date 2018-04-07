#!/bin/bash
# Determine the difference in impact of corun execution on 'bfs' slowdown when
# the said corunner are executing on Denver cores Vs when they are using the
# Cortex-A57 cores

. ./functions.sh
scenario=denver

echo -e "${YLW}[STATUS] Executing HISTO with 2-CortexA57 corunners${NCL}"
execute_parboil 2 histo cuda large ${scenario} UNLOCKED
echo -e "${YLW}[STATUS] Executing HISTO with 2-Denver corunners${NCL}"
execute_parboil_denver 2 histo cuda large ${scenario} UNLOCKED

setup_bwlock 512 0
echo -e "${YLW}[STATUS] Executing HISTO with 2-CortexA57 corunners with BWLOCK++${NCL}"
execute_parboil 2 histo cuda large ${scenario} LOCKED
echo -e "${YLW}[STATUS] Executing HISTO with 2-Denver corunners with BWLOCK++${NCL}"
execute_parboil_denver 2 histo cuda large ${scenario} LOCKED
cleanup_bwlock
