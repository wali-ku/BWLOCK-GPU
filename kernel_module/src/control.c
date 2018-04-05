#include "common.h"

extern u32		sysctl_llc_throttle_events;
extern u32		sysctl_tfs_throttle_factor;
extern u32		sysdbg_reset_throttle_time;
extern u64		sysdbg_total_throttle_time;
extern struct dentry 	*bwlockmod_dir;

int init_bwlock_controlfs (void)
{
	umode_t mode = S_IFREG | S_IRUSR | S_IWUSR;

	/* Create directory for bwlock parameters under /sys/kernel/debug */
	bwlockmod_dir = debugfs_create_dir ("bwlock", NULL);

	if (!bwlockmod_dir)
		return PTR_ERR (bwlockmod_dir);

	/* Create control parameter for setting allowed corun bandwidth */
	if (!debugfs_create_u32 ("corun_threshold_events", mode, bwlockmod_dir, &sysctl_llc_throttle_events))
		goto fail;

	/* Create control parameter for setting allowed corun bandwidth */
	if (!debugfs_create_u32 ("tfs_throttle_factor", mode, bwlockmod_dir, &sysctl_tfs_throttle_factor))
		goto fail;

	/* Create throttling related parameters */
	if (!debugfs_create_u32 ("reset_throttle_time", mode, bwlockmod_dir, &sysdbg_reset_throttle_time))
		goto fail;

	if (!debugfs_create_u64 ("system_throttle_time", mode, bwlockmod_dir, &sysdbg_total_throttle_time))
		goto fail;

	return 0;

fail:
	debugfs_remove_recursive (bwlockmod_dir);
	return -ENOMEM;
}
