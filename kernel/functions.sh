#!/bin/bash
# Helper bash functions for building Linux for Tegra 28.1 kernel on TX-2
#
# Author:	Waqar Ali (wali@ku.edu)
#
# ACKNOWLEDGMENT
# Parts of this script have been adpated from:
# 	https://github.com/jetsonhacks/buildJetsonTX2Kernel.git

# Declare colors for pretty output
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[0;36m'
NCL='\033[0m'

get_kernel_sources () {
	pushd . &> /dev/null
	apt-add-repository universe
	apt-get update
	apt-get install qt5-default pkg-config -y
	mkdir -p linux 
	cd linux
	echo -e "${GRN}[STATUS] Fetching kernel source${NCL}"
	wget http://developer.download.nvidia.com/embedded/L4T/r28_Release_v1.0/BSP/source_release.tbz2
	
	echo -e "${GRN}[STATUS] Extracting kernel source${NCL}"
	tar -xvf source_release.tbz2 sources/kernel_src-tx2.tbz2
	tar -xvf sources/kernel_src-tx2.tbz2
	
	echo -e "${GRN}[STATUS] Removing extraneous components${NCL}"
	rm -rf source_release.tbz2
	echo -e "${GRN}[STATUS] Extraction complete!${NCL}"
	popd &> /dev/null
}

patch_kernel_tree () {
	pushd . &> /dev/null
	echo -e "${GRN}[STATUS] Patching Linux for Tegra kernel${NCL}"
	patch linux/kernel/kernel-4.4/drivers/devfreq/Makefile miscs/diffs/devfreq/devfreq.patch
	patch linux/kernel/nvgpu/drivers/gpu/nvgpu/Makefile miscs/diffs/nvgpu/nvgpu.patch
	patch linux/kernel/kernel-4.4/sound/soc/tegra-alt/Makefile miscs/diffs/tegra-alt/tegra-alt.patch
	cp linux/kernel/kernel-4.4/drivers/media/platform/tegra/mipical/mipi_cal.h linux/kernel/kernel-4.4/drivers/media/platform/tegra/mipical/vmipi/mipi_cal.h
	cp miscs/dot_config linux/kernel/kernel-4.4/.config
	cp miscs/bwlock++.patch linux/kernel/kernel-4.4/.
	cd linux/kernel/kernel-4.4/
	patch -p1 < bwlock++.patch
	rm bwlock++.patch
	echo -e "${GRN}[STATUS] Patching complete!${NCL}"
	popd &> /dev/null
}

build_kernel_tree () {
	pushd . &> /dev/null
	cd linux/kernel/kernel-4.4/
	echo -e "${GRN}[STATUS] Building Linux for Tegra Kenrel${NCL}"
	echo -e "${GRN}[STATUS] Preparing configuration file${NCL}"
	make oldconfig
	make prepare
	make modules_prepare
	echo -e "${GRN}[STATUS] Executing the kernel build${NCL}"
	make -j6 Image
	echo -e "${GRN}[STATUS] Building kernel modules${NCL}"
	make modules
	echo -e "${GRN}[STATUS] Installing kernel modules${NCL}"
	make modules_install
	
	if [ -f arch/arm64/boot/Image ]; then
		echo -e "${GRN}[STATUS] Kernel image has now been built successfully${NCL}"
	else
		echo -e "${GRN}[ERROR] Something went wrong while building the kernel image!${NCL}"
	fi
	popd &> /dev/null
}

# CAUTION: Make sure that there were no errors while building the kernel image
# before copying the new image to /boot/ directory. You may also want to
# create a backup of your current kernel image before copying the new one
copy_kernel_image () {
	if [ -f linux/kernel/kernel-4.4/arch/arm64/boot/Image ]; then
		cp linux/kernel/kernel-4.4/arch/arm64/boot/Image /boot/.
		echo -e "${GRN}[STATUS] Copied kernel image to /boot/ directory. The new kernel is now ready to boot!${NCL}"
	else
		echo -e "${RED}[ERROR] A valid kernel image was not found in linux/kernel/kernel-4.4/arch/arm64/boot/ directory!${NCL}"
	fi
}
