# Introduction
This repository contains all the scripts needed to reproduce experiments from
our ECRTS-18 paper:

**Protecting Real-Time GPU Kernels on Integrated CPU-GPU SoC Platforms**

# Pre-requisites
### Hardware
+ NVIDIA Jetson TX-2 Board

### Software
+ CUDA Runtime Library (Version-8.0)
+ Linux for Tegra (Version 28.1)
+ Python (Version 2.7)
+ Git
+ Matplotlib

# Directory Structure
  * [kernel: Placeholder directory for hosting Linux for Tegra kernel]( ./kernel)
     * [miscs: Contains required kernel patches]( ./kernel/miscs)
       * [diffs]( ./kernel/miscs/diffs)
       * [devfreq]( ./kernel/miscs/diffs/devfreq)
       * [nvgpu]( ./kernel/miscs/diffs/nvgpu)
       * [tegra-alt]( ./kernel/miscs/diffs/tegra-alt)
   * [dynamic_linker: Contains shared library code for intercepting CUDA Runtime API calls]( ./dynamic_linker)
     * [lib]( ./dynamic_linker/lib)
   * [kernel_module: Contains source code of BWLOCK++ kernel module]( ./kernel_module)
     * [test]( ./kernel_module/test)
       * [rt_test]( ./kernel_module/test/rt_test)
     * [src]( ./kernel_module/src)
   * [benchmarks: Placeholder directory for hosting benchmarks]( ./benchmarks)
   * [scripts: Contains bash and python scripts for automatically running BWLOCK++ experiments]( ./scripts)
       * [graph_scripts]( ./scripts/graph_scripts)
       * [individual_figures]( ./scripts/individual_figures)

# Step-by-step Instructions
We recommend that the TX-2 be flashed with [Jetpack-3.1](https://developer.nvidia.com/embedded/jetpack-3_1) before proceeding with the following steps. All these steps are meant to be executed on the TX-2 board.

1. Launch a bash shell. Install Git
```bash
sudo apt-get install git
```

2. Clone this repository
```bash
git clone https://github.com/Skidro/BWLOCK-GPU.git
```

3. Launch a sudo shell
```
sudo bash
```

4. Install BWLOCK++ patched kernel on board (Long Operation). All the steps required to do so are automated in this [script]( ./kernel/RUN-ME.sh). Please note that this requires an active internet connection.
```bash
cd BWLOCK-GPU/kernel
./RUN-ME.sh
```

5. Reboot the system. Go to the BWLOCK-GPU git repository
6. Setup the benchmarks used in BWLOCK++ evaluation. This is automated by the following script [script]( ./benchmarks/RUN-ME.sh). Please note that this requires an active internet connection.
```bash
cd benchmarks
./RUN-ME.sh
cd ..
```

7. **\[IMPORTANT\]** Set root path in [this script]( ./scripts/functions.sh). The root path is defined as the absolute path in your system where the BWLOCK-GPU repostiory is located. For example, in our test sytem, the repository is located at */home/nvidia/BWLOCK-GPU* which is set as the root path.

8. Launch sudo shell
```bash
sudo bash
```

9. Build all the test materials (benchmarks and kernel module). This is automated by the following script [script]( ./scripts/build_all.sh)
```bash
cd scripts
./build_all.sh
```

10. Put the board into maximum performance state using this script [script]( ./scripts/max_perf.sh)
```bash
./max_perf.sh
```

11. Run the [sanity check experiment]( ./scripts/TEST-BWLOCK.sh) to verify that everything is correctly setup in your system. The script takes ~1-minute to complete.
```bash
./TEST-BWLOCK.sh
```

12. Given that your system passes the sanity check, BWLOCK++ is ready to be evaluated on it. However, before proceeding with the final script, install the *matplotlib* package which is used by the final script for plotting graphs.
```bash
apt-get install python-matplotlib
```

13. Run the [final evaluation script]( ./scripts/RUN-ME.sh) which runs all the experiments from our paper (Protecting Real-Time GPU Kernels on Integrated CPU-GPU SoC Platforms). This will take significant amount of time (Approximately 2 to 3 hours).
```bash
./RUN-ME.sh
```

14. If everything goes alright, the following directory (scripts/figures) should contain all the generated figures.

# Experiments
**NOTE: Before running the experiments, make sure that the device is in max-performance state**
