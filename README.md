# Introduction
This repository contains all the scripts needed to reproduce experiments from
our ECRTS-18 paper:
**Protecting Real-Time GPU Kernels on Integrated CPU-GPU SoC Platforms**

# Pre-requisites
### Hardware
+ NVIDA Jetson TX-2 Board
+ SSD (Optional)

### Software
+ CUDA Runtime Library (Version-8.0)
+ Linux for Tegra (Version 28.1)
+ Python (Version 2.7)
+ Matplotlib

# Directory Structure
* [root: This directory]( .)
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

# Setup
We recommend that the TX-2 be flashed with Jetpack-3.0 before proceeding with
the following steps.

# Experiments
**NOTE: Before running the experiments, make sure that the device is in max-performance state**
