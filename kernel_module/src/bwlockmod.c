/*
 * FILE		: perfmod.c
 * BRIEF	: This is a basic kernel module which illustrates the usage of
 * 		  perf events inside linux kernel
 *
 * Copyright (C) 2017 Waqar Ali <wali@ku.edu>
 *
 * This file is distributed under the University of Kansas Open Source
 * License. See LICENSE.TXT for details.
 *
 */

/**************************************************************************
 * Special Conditional Compilation Information
 *************************************************************************/
#define pr_fmt(fmt) 		KBUILD_MODNAME ": " fmt

/**************************************************************************
 * Included Files
 *************************************************************************/

/* Include the function prototypes for this module's local functions */
#include "common.h"
#include "bwlockmod.h"

/**************************************************************************
 * Global Variables
 **************************************************************************/
struct perfmod_info		perfmod_info;
struct core_info __percpu	*core_info;
int				g_period_us 			= 1000;

/* Define initial event limits */
int				sysctl_maxperf_bw_mb		= 10000;
int				sysctl_throttle_bw_mb		= 100;
u32				sysctl_llc_maxperf_events	= 163840;	// 10000 MBps
u32				sysctl_llc_throttle_events	= 1638;		// 100 MBps

/* Pointer to the BWLOCK++ directory under debugfs */
struct dentry			*bwlockmod_dir;

/* Define throttle punishment factor. This parameter decides how much a
   bandwidth intensive non-RT thread should be punished in the presence
   of bandwidth locked threads */
u32				sysctl_tfs_throttle_factor	= 0;
u32				sysdbg_reset_throttle_time 	= 0;
u64				sysdbg_total_throttle_time 	= 0;

/**************************************************************************
 * Function Definitions
 **************************************************************************/
/*
 * init_module
 * Module initialization routine. Sets up perf counters and overflow callbacks
 */
int init_module (void)
{
	int i, ret = 0;
	struct perfmod_info *global = &perfmod_info;

	/* Reset the perfmod data structure */
	memset (global, 0, sizeof (struct perfmod_info));

	/* Allocate data structure to keep track of per-core statistics */
	core_info = alloc_percpu (struct core_info);
	smp_mb ();

	/* Prevent state change for online CPUs */
	get_online_cpus ();

	/* Perform per-cpu initialization */
	for_each_online_cpu (i) {
		/* Obtain the core-info pointer for this core */
		struct core_info *cinfo = per_cpu_ptr (core_info, i);
		memset (cinfo, 0, sizeof (struct core_info));
		smp_mb ();

		cinfo->init_thread = kthread_create_on_node (lazy_init_thread,
							     (void *)((unsigned long) i),
							     cpu_to_node (i),
							     "kinit/%d", i);
		kthread_bind (cinfo->init_thread, i);
		wake_up_process (cinfo->init_thread);
	}

	/* Initialize BWLOCK++ debugfs */
	ret = init_bwlock_controlfs ();

	if (ret)
		trace_printk ("[ERROR] Unable to initialize debugfs components\n");

	/* Initialization complete */
	return 0;
}

/*
 * lazy_init_thread
 * Per core initialization thread that can invoke sleeping functions
 */
int lazy_init_thread (void *arg)
{
	int i = smp_processor_id ();
	struct core_info *cinfo = this_cpu_ptr (core_info);

	/* Initialize per-core parameters */
	smp_rmb ();
	cinfo->core_throttle_duration = 0;
	cinfo->core_throttle_period_cnt = 0;
	cinfo->throttle_core = 0;
	cinfo->budget = convert_mb_to_events (sysctl_maxperf_bw_mb);
	init_waitqueue_head (&cinfo->throttle_evt);
	init_irq_work (&cinfo->pending, perfmod_process_overflow);
	smp_wmb ();

	cinfo->event = init_counter (i, cinfo->budget);

	/* Check if the event was successfully created */
	if (!cinfo->event) {
		trace_printk ("Failed to create event on core (%d)\n", i);
		return -1;
	} else {
		trace_printk ("Initialized perf counter on core (%d)\n", i);
	}

	__start_counter (NULL);

	trace_printk ("Initialization complete on core-%2d\n", i);

	/* Create and wake-up throttle threads */
	cinfo->throttle_thread = kthread_create_on_node (throttle_thread,
							 (void *)((unsigned long) i),
							 cpu_to_node (i),
							 "kthrottle/%d", i);

	/* Bind the throttle thread to core */
	kthread_bind (cinfo->throttle_thread, i);
	wake_up_process (cinfo->throttle_thread);

	/* Configure a periodic timer interrupt to trigger bandwidth budget
	   replenishment on this core */
	get_cpu ();
	cinfo->period_in_ktime = ktime_set (0, g_period_us * K1);
	hrtimer_init (&cinfo->hrtimer, CLOCK_MONOTONIC, HRTIMER_MODE_REL_PINNED);
	(&cinfo->hrtimer)->function = &periodic_timer_callback;
	hrtimer_start (&cinfo->hrtimer, cinfo->period_in_ktime, HRTIMER_MODE_REL_PINNED);
	put_cpu ();

	return 0;
}

/*
 * cleanup_module
 * This function cleans up after the perfmod kernel module
 */
void cleanup_module (void)
{
	int i;
	struct perfmod_info *global = &perfmod_info;

	/* Place a memory barrier to synchronize across system cores */
	smp_mb ();

	/* Refresh the online cpu information */
	get_online_cpus ();

	/* Stop performance counters */
	disable_counters ();

	/* Destroy perf objects */
	for_each_online_cpu (i) {
		struct core_info *cinfo = per_cpu_ptr (core_info, i);

		hrtimer_cancel (&cinfo->hrtimer);
		perf_event_disable (cinfo->event);
		perf_event_release_kernel (cinfo->event);

		/* Print the debug message to trace buffer */
		trace_printk ("Stopping kthrottle/%d\n", i);

		/* Core should not be considered throttled at this point */
		cinfo->throttle_core = 0;
		smp_mb ();
		kthread_stop (cinfo->throttle_thread);

		/* Before leaving, update the total system throttle time */
		global->system_throttle_duration += cinfo->core_throttle_duration;
		global->system_throttle_period_cnt += cinfo->core_throttle_period_cnt;

		/* Print this core's throttle times to trace buffer */
		DEBUG_TIME(trace_printk("[TIME] Core-%d Throttle Duration : %llu ms\n", i, div64_u64 (cinfo->core_throttle_duration, M1)));
		DEBUG_TIME(trace_printk("[TIME] Core-%d Throttle Periods  : %llu\n", i, cinfo->core_throttle_period_cnt));
	}

	/* Free dynamically allocated data inside perfmod structure */
	free_percpu (core_info);

	/* Print cleanup message to trace buffer */
	DEBUG_TIME(trace_printk ("[TIME] Total System Throttle Duration : %llu ms\n", div64_u64 (global->system_throttle_duration, M1)));
	DEBUG_TIME(trace_printk ("[TIME] Total System Throttle Periods : %llu\n", global->system_throttle_period_cnt));

	/* Remove debugfs directories */
	debugfs_remove_recursive (bwlockmod_dir);
	trace_printk ("BWLOCK kernel module has been successfully removed!\n");

	/* Cleanup complete */
	return;
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Waqar Ali <wali@ku.edu>");
