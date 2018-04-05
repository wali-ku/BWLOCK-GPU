#!/bin/bash
# This script contains helper functions for automatically downloading,
# extracting and patching benchmarks used for the evaluations of BWLOCK++
#
# Author:	Waqar Ali (wali@ku.edu)

. ./functions.sh


echo -e "${CYN}***** Step [1/4]${NCL}"
fetch_isolbench

echo -e "${CYN}***** Step [2/4]${NCL}"
fetch_parboil

echo -e "${CYN}***** Step [3/4]${NCL}"
extract_parboil

echo -e "${CYN}***** Step [4/4]${NCL}"
patch_parboil
