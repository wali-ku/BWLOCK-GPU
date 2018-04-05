#!/bin/bash
# Helper functions for setting up the benchmarks
#
# Author:	Waqar Ali (wali@ku.edu)

# Declare colors for pretty output
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
CYN='\033[0;36m'
NCL='\033[0m'

# Download IsolBench suite from Git
fetch_isolbench () {
	echo -e "${GRN}[STATUS] Cloning IsolBench${NCL}"
	git clone https://github.com/CSL-KU/IsolBench.git &> /dev/null

	if [ ! -d IsolBench ]; then
		echo -e "${RED}[ERROR] Unable to clone IsolBench!${NCL}"
	fi
}

# Download parboil benchmark from my own git repository
# NOTE: Parboil benchmark can be downloaded from the official site as well:
# http://impact.crhc.illinois.edu/parboil/parboil_download_page.aspx
# If downloaded from the official website, please create a directory here with
# the name 'parboil' and place the three archive files (pb2.5driver.tgz,
# pb2.5benchmarks.tgz and pb2.5datasets_standard.tgz) in it
#
# However, for the sake of automation in this artifact evaluation effort, I
# have hosted the unmodified Parboil suite archive files on my personal
# website so that they may be easily downloaded here using this function
fetch_parboil () {
	pushd . &> /dev/null
	echo -e "${GRN}[STATUS] Downloading Parboil suite from personal mirror${NCL}"
	mkdir parboil
	cd parboil
	echo -e "${GRN}         - Downloading driver archive    | <Size: 48-KBytes>${NCL}"
	wget http://ittc.ku.edu/~wali/benchmarks/pb2.5driver.tgz &> /dev/null
	echo -e "${GRN}         - Downloading benchmark archive | <Size: 2.5-MBytes>${NCL}"
	wget http://ittc.ku.edu/~wali/benchmarks/pb2.5benchmarks.tgz &> /dev/null
	echo -e "${GRN}         - Downloading datasets archive  | <Size: 354-MBytes>${NCL}"
	wget http://ittc.ku.edu/~wali/benchmarks/pb2.5datasets_standard.tgz &> /dev/null
	popd &> /dev/null
}

# Extract parboil benchmarks
extract_parboil () {
	archives=('pb2.5driver.tgz' 'pb2.5benchmarks.tgz' 'pb2.5datasets_standard.tgz')
	names=('Driver' 'Benchmarks' 'Datasets')
	duration=('Short' 'Short' 'Long')
	pushd . &> /dev/null
	echo -e "${GRN}[STATUS] Extracting Parboil suite${NCL}"
	cd parboil
	for number in `seq 0 $((${#archives[@]} - 1))`; do
		printf "${GRN}         - Extracting %12s | Expected Duration: ${duration[${number}]}${NCL}\n" "${names[${number}]}"
		tar -xvzf ${archives[${number}]} &> /dev/null
		rm -f ${archives[${number}]}
	done
	mv parboil driver1234
	mv driver1234/* .
	rm -r driver1234
	popd &> /dev/null
}

# Patch parboil benchmarks
patch_parboil () {
	pushd . &> /dev/null
	echo -e "${GRN}[STATUS] Patching Parboil suite${NCL}"
	cp parboil.patch parboil/.
	cd parboil
	patch -p1 < parboil.patch
	rm -f parboil.patch
	popd &> /dev/null
}
