#include "common.h"

/**************************************************************************
 * Global Variables
 **************************************************************************/
extern struct core_info __percpu	*core_info;

/* Define initial event limits */
extern u32				sysctl_llc_maxperf_events;
extern u32				sysctl_llc_throttle_events;

/*
 * period_timer_callback
 * This function is triggered in reponse to the HR-timer expiration. Its job is
 * to replenish the core's budget as per the system state
 */
enum hrtimer_restart periodic_timer_callback (struct hrtimer *timer)
{
	struct core_info *cinfo = this_cpu_ptr (core_info);
	int bwlock_core_cnt, over_run_cnt;

	/* Forward the hrtimer and get the number of overruns */
	over_run_cnt = hrtimer_forward_now (timer, cinfo->period_in_ktime);

	if (over_run_cnt == 0)
		goto done;

	/* Replenish perf-event count for this core */
	cinfo->event->pmu->stop (cinfo->event, PERF_EF_UPDATE);

	/* Check if the core needs to be throttled */
	bwlock_core_cnt = nr_bwlocked_cores ();
	if (bwlock_core_cnt > 0 && current->bwlock_val == 0) {
		if ((rt_task (current) && cinfo->throttle_core != 1))
			/* Give the core maximum bandwidth since it is executing a real-time
			   task which is not kthrottle */
			cinfo->budget = sysctl_llc_maxperf_events;
		else
			/* Throttle the core */
			cinfo->budget = sysctl_llc_throttle_events;
	} else
		/* Give the core maximumum bandwidth */
		cinfo->budget = sysctl_llc_maxperf_events;

	cinfo->event->hw.sample_period = cinfo->budget;
	local64_set (&cinfo->event->hw.period_left, cinfo->budget);
	cinfo->event->pmu->start (cinfo->event, PERF_EF_RELOAD);

	if (cinfo->throttled_task) {
		DEBUG_MONITOR (trace_printk ("[MONITOR] Task: %10s | V-Time: %10lld | THROTTLED\n",
					      cinfo->throttled_task->comm,
					      cinfo->throttled_task->se.vruntime));

		/* This will stop kthrottle */
		cinfo->throttle_core = 0;
	} else {
		DEBUG_MONITOR (trace_printk ("[MONITOR] Task: %10s | V-Time: %10lld\n",
					      current->comm,
					      current->se.vruntime));
	}

	smp_mb ();

done:
	/* Return to the caller */
	return HRTIMER_RESTART;
}
