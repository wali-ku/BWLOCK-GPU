#include "common.h"

/**************************************************************************
 * Global Variables
 **************************************************************************/
extern struct core_info __percpu	*core_info;
extern int				g_period_us;

/*
 * convert_mb_to_events
 * This function converts memory bandwidth into LLC-events according to the
 * following formula:
 *
 * Events (LLC Misses) = (Bandwidth (MB/s) * 1 M * Duration) / (LLC Line Size)
 */
u64 convert_mb_to_events (int mb)
{
	/* Return the answer to the caller */
	return div64_u64 ((u64)mb * 1024 * 1024, CACHE_LINE_SIZE * (1000000 / g_period_us));
}

/*
 * convert_events_to_mb
 * This function converts (and ceils) the LLC-miss events into memory bandwidth
 */
int convert_events_to_mb (u64 events)
{
	int divisor = g_period_us * 1024 * 1024;
	int mb = div64_u64 (events * CACHE_LINE_SIZE * 1000000 + (divisor - 1), divisor);

	/* Return the calculated mega-bytes value to caller */
	return mb;
}

/*
 * perf_event_count
 * This function calculates the number of performance monitoring events which have
 * been registered so far in the current period
 */
u64 perf_event_count (struct perf_event *event)
{
	u64 event_count = local64_read (&event->count);
	u64 child_count = atomic64_read (&event->child_count);
	u64 total_count = event_count + child_count;

	/* Return the total PMC event count */
	return total_count;
}

/*
 * init_counter
 * This function initializes the performance counters to count the desired
 * events
 */
struct perf_event* init_counter (int cpu,
				 int budget)
{
	struct perf_event *event = NULL;

	/* Describe the attributes of the PMC event to be counted */
	struct perf_event_attr sched_perf_hw_attr = {
		.type		= PERF_TYPE_RAW,
		.config		= 0x17,
		.size		= sizeof (struct perf_event_attr),
		.pinned		= 1,
		.disabled	= 1,
		.exclude_kernel	= 1,
		.sample_period	= budget
	};

	/* Create perf kernel counter with the desired attributes */
	event = perf_event_create_kernel_counter (&sched_perf_hw_attr,
						  cpu,
						  NULL,
						  event_overflow_callback,
						  NULL
						  );

	/* Return the created event to caller */
	return event;
}

/*
 * __start_counter
 * This function starts the PM-event counter on a particular core
 */
void __start_counter (void *info)
{
	struct core_info *cinfo = this_cpu_ptr (core_info);
	trace_printk ("Perf counter started on core-%2d\n", (int) smp_processor_id ());

	/* Kick off the PMC event counting */
	perf_event_enable (cinfo->event);
	cinfo->event->pmu->add (cinfo->event, PERF_EF_START);

	/* Return to the caller */
	return;
}

/*
 * start_counters
 * This function starts PM-event counters on all cores
 */
void start_counters (void)
{
	/* Invoke the start counter function on each core */
	on_each_cpu (__start_counter, NULL, 0);

	/* All done here */
	return;
}

/*
 * __disable_counter
 * This function disables the performance counter on a particular core
 */
void __disable_counter (void *info)
{
	struct core_info *cinfo = this_cpu_ptr (core_info);

	/* Stop the perf counter */
	cinfo->event->pmu->stop (cinfo->event, PERF_EF_UPDATE);
	cinfo->event->pmu->del (cinfo->event, 0);

	/* Return to caller */
	return;
}

/*
 * disable_counters
 * This function invokes counter disable function on each system core
 */
void disable_counters (void)
{
	/* Invoke the __disable_counter function on each cpu */
	on_each_cpu (__disable_counter, NULL, 0);

	/* All done here */
	return;
}
