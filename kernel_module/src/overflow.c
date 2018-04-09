#include "common.h"

/**************************************************************************
 * Global Variables
 **************************************************************************/
extern struct perfmod_info		perfmod_info;
extern struct core_info __percpu	*core_info;
extern int				g_period_us;

/* Define throttle punishment factor. This parameter decides how much a
   bandwidth intensive non-RT thread should be punished in the presence
   of bandwidth locked threads */
extern u32				sysctl_tfs_throttle_factor;

/*
 * event_overflow_callback
 * This is the IRQ handler associated with PMC overflow interrupt. This function invokes
 * the current event handling function on the core on which it executes
 */
void event_overflow_callback (struct perf_event *event,
			      struct perf_sample_data *data,
			      struct pt_regs *regs)
{
	struct core_info *cinfo = this_cpu_ptr (core_info);

	/* Mark work to be done against this irq as pending */
	irq_work_queue (&cinfo->pending);

	/* All done here */
	return;
}

/*
 * perfmod_process_overflow
 *
 * This function performs the work associated with PMC overflow interrupt on a
 * specific core
 */
void perfmod_process_overflow (struct irq_work* entry)
{
	struct core_info *cinfo = this_cpu_ptr (core_info);
	// int bwlock_core_cnt = nr_bwlocked_cores ();
	// int i = smp_processor_id ();;

	DEBUG_OVERFLOW (trace_printk ("[STATUS] Overflow on Core-%d\n", i));

	/* Stop counter */
	cinfo->event->pmu->stop (cinfo->event, PERF_EF_UPDATE);

	/* Reprogram the interrupt to stop triggering during this
	 * period */
	local64_set (&cinfo->event->hw.period_left, 0xffffffff);

	/* Enable performance counter */
	cinfo->event->pmu->start (cinfo->event, PERF_EF_RELOAD);

	// if ((current->bwlock_val == 0) && !rt_task (current) && bwlock_core_cnt > 0) {
	if (!rt_task (current)) {
		/* In case of throttling based design, we just need to wake up
		 * the high priority kernel thread on the target core so that
		 * it may not execute anything that can cause memory traffic
		 * for the remainder of the cycle */
		cinfo->throttle_core = 1;
		smp_mb ();

		cinfo->throttled_task = current;

		/* Print to trace buffer */
		DEBUG_OVERFLOW (trace_printk ("[STATUS] Throttling thread : %s\n", current->comm));
		wake_up_interruptible (&cinfo->throttle_evt);
	}

	/* Return to caller */
	return;
}

/*
 * throttle_thread
 *
 * This function defines the behavior of throttle thread which is used to
 * block a core which has consumed its bandwidth budget
 */
int throttle_thread (void *arg)
{
	int cpunr = (unsigned long)arg;
	struct core_info *cinfo = per_cpu_ptr (core_info, cpunr);
	u64 delta_time;

	/* Declare this as a high priority task in the system */
	static const struct sched_param param = {
		.sched_priority = MAX_USER_RT_PRIO / 2,
	};

	/* Set this thread with real-time priority */
	sched_setscheduler (current, SCHED_FIFO, &param);

	while (!kthread_should_stop () && cpu_online (cpunr)) {
		/* Wait for something to happen */
		wait_event_interruptible (cinfo->throttle_evt,
					  cinfo->throttle_core || kthread_should_stop ());

		/* Mark the beginning of throttle time */
		cinfo->core_throttle_start_mark = ktime_get ();

		/* Print status message to debug buffer */
		DEBUG_OVERFLOW (trace_printk ("Throttle thread awakened on Core-%2d\n", cpunr));

		/* Something happened. Break the loop if the thread should be
		 * stopped */
		if (kthread_should_stop ())
			break;

		/* Place a memory barrier to synchronize across cpus */
		smp_mb ();

		while (cinfo->throttle_core && !kthread_should_stop ()) {
			cpu_relax ();
			smp_mb ();
		}

		/* Mark the end of throttle time */
		delta_time = (u64) (ktime_get ().tv64 - cinfo->core_throttle_start_mark.tv64);

		spin_lock (&cinfo->core_lock);
		cinfo->core_throttle_duration += delta_time;
		spin_unlock (&cinfo->core_lock);

		cinfo->core_throttle_period_cnt++;

		/* We should have a throttle thread */
		if (cinfo->throttled_task) {
			/* Update the vruntime of the throttled task to keep CFS behavior normal */
			cinfo->throttled_task->se.vruntime += (sysctl_tfs_throttle_factor * delta_time);

			/* Synchronize across smp cores */
			smp_mb ();

			/* Remove the throttled task */
			cinfo->throttled_task = NULL;
		} else {
			trace_printk ("\n[ERROR] No throttled task!\n\n");
		}

		/* Print status message to debug buffer */
		DEBUG_OVERFLOW (trace_printk ("Throttle thread sleeping on Core-%2d\n", cpunr));
	}

	/* Return to caller */
	return 0;
}
