#!/bin/bash
# NOTE: MUST BE EXECUTED AS SUDO
# This is a comprehensive script which will:
# 	- Download Linux for Tegra 28.1 from NVIDIA repositories (INTERNET CONNECTION REQUIRED)
# 	- Patch the kernel with BWLOCK++
# 	- Build the kernel and all the modules
# 	- Copy the kernel image to /boot/ directory (CAUTION!!!)
#
# Author:	Waqar Ali (wali@ku.edu)

. ./functions.sh

echo -e "${CYN}***** Step [1/4]${NCL}"
get_kernel_sources

echo -e "${CYN}***** Step [2/4]${NCL}"
patch_kernel_tree

echo -e "${CYN}***** Step [3/4]${NCL}"
build_kernel_tree

echo -e "${CYN}***** Step [4/4]${NCL}"
copy_kernel_image
