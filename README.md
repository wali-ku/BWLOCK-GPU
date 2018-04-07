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
**\[Pre-Requisite\]** We require that the TX-2 be flashed with [Jetpack-3.1](https://developer.nvidia.com/embedded/jetpack-3_1) before proceeding with the following steps. **Please note that flashing the board will erase all data from its internal storage so please back-up any important material you have on your TX-2 board before proceeding any further**. All these steps are meant to be executed on the TX-2 board.

1. Launch a bash shell. Install Git.
```bash
sudo apt-get install git
```

2. Clone this repository.
```bash
git clone https://github.com/Skidro/BWLOCK-GPU.git
```

3. Launch a sudo shell.
```
sudo bash
```

4. Install BWLOCK++ patched kernel on board (Long Operation - ~1 Hour). All the steps required to do so are automated in this [script (RUN-ME.sh)]( ./kernel/RUN-ME.sh) located in *BWLOCK-GPU/kernel/* directory. Please note that this requires an active internet connection.

**\[CAUTION\]** Please note that running this script will over-write the existing kernel in the */boot/* directory on your TX-2 board!

```bash
cd BWLOCK-GPU/kernel
./RUN-ME.sh
```

5. **Reboot the system**. Go to the BWLOCK-GPU git repository
6. Setup the benchmarks used in BWLOCK++ evaluation. This is automated by the following [script (RUN-ME.sh)]( ./benchmarks/RUN-ME.sh) in *BWLOCK-GPU/benchmarks/* directory. Please note that this requires an active internet connection.
```bash
cd benchmarks
./RUN-ME.sh
cd ..
```

7. **\[IMPORTANT\]** Set root path variable (**root_path**) in [this script (functions.sh)]( ./scripts/functions.sh) located in *BWLOCK-GPU/scripts/* directory. The root path is defined as the absolute path in your system where the BWLOCK-GPU repository is located. For example, in our test sytem, the repository is located at */home/nvidia/BWLOCK-GPU* which is set as the root path.

8. Launch sudo shell
```bash
sudo bash
```

9. Build all the test materials (benchmarks and kernel module). This is automated by the following [script (build_all.sh)]( ./scripts/build_all.sh) located in *BWLOCK-GPU/scripts/* directory.
```bash
cd scripts
./build_all.sh
```

10. Run the [sanity check experiment (TEST-BWLOCK.sh)]( ./scripts/TEST-BWLOCK.sh) located in *BWLOCK-GPU/scripts/* directory; to verify that everything is correctly setup in your system. The script takes ~1-minute to complete.
```bash
./TEST-BWLOCK.sh
```

11. Given that your system passes the sanity check, BWLOCK++ is ready to be evaluated on it. However, before proceeding with the final script, install the *matplotlib* package which is used by the final script for plotting graphs.
```bash
apt-get install python-matplotlib
```
12. **Reboot the system**. Once the system reboots, go to the directory *BWLOCK-GPU/scripts*. Relaunch sudo shell and then put the board into maximum performance state using this [script (max_perf.sh)]( ./scripts/max_perf.sh) located in *BWLOCK-GPU/scripts/* directory.

**\[NOTE\]** The script (max_perf.sh) will shutdown the GUI on TX-2 board. We suggest that you switch to a TTY terminal (CTRL + ALT + \<Function-Key\>) before executing this script!

```bash
sudo bash
cd BWLOCK-GPU/scripts
./max_perf.sh
```

13. Run the [final evaluation script (RUN-ME.sh)]( ./scripts/RUN-ME.sh) located in *BWLOCK-GPU/scripts/* directory; which runs all the experiments from our paper (Protecting Real-Time GPU Kernels on Integrated CPU-GPU SoC Platforms). This will take significant amount of time (Approximately 2 to 3 hours).
```bash
./RUN-ME.sh
```

14. If everything goes alright, the following directory (*BWLOCK-GPU/scripts/figures/*) should contain all the generated figures.

# Figures Reproduced from Paper
By following the instructions mentioned [above](https://github.com/Skidro/BWLOCK-GPU#step-by-step-instructions), the following figures from the paper should get generated in (*BWLOCK-GPU/scripts/figures/*) directory:
+ Figure-1
+ Figure-5 (a, b, c)
+ Figure-6 (a, b, c)
+ Figure-7
+ Figure-8
+ Figure-9
+ Figure-10

# Running a Specific Experiment from Paper
In case, one of the individual figures need to be generated from the figures mentioned [above](https://github.com/Skidro/BWLOCK-GPU#figures-reproduced-from-paper), please use the scripts present in [this folder (individual_figures)]( ./scripts/individual_figures) which is located in the *BWLOCK-GPU/scripts/* directory. In order to do that, either copy the script for the figure you want to reproduce form the directory (*BWLOCK-GPU/scripts/individual_figures/*) to the directory (*BWLOCK-GPU/scripts/*) and then run it OR change the directory to *BWLOCK-GPU/scripts* and execute the script directly from there (As demonstrated below).

**\[NOTE\]** By default, the scripts in *individual_figures* directory will plot the figure with the existing data in *results* directory. However, if the data itself needs to be collected, the script should be run with **run_the_experiment** option.

```bash
# Current Directory: BWLOCK-GPU/scripts
# The following command will plot Figure-1 using the existing data in results/motivation folder
./individual_figures/fig1-motivation.sh

# The following command will collect the data for Figure-1 and then plot the graph using the new data
./individual_figures/fig1-motivation.sh run_the_experiment
```
