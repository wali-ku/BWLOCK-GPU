#include "common.h"

extern struct core_info __percpu	*core_info;
extern struct perfmod_info		perfmod_info;
extern struct dentry 			*bwlockmod_dir;
extern u32				sysctl_llc_throttle_events;
extern u32				sysctl_tfs_throttle_factor;

static int bwlock_throttle_open (struct inode*, struct file*);
static int bwlock_throttle_show (struct seq_file*, void *);

static const struct file_operations bwlock_throttle_fops = {
	.open		= bwlock_throttle_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int bwlock_throttle_open (struct inode *inode, struct file *filp)
{
	return single_open (filp, bwlock_throttle_show, NULL);
}

static int bwlock_throttle_show (struct seq_file *m, void *v)
{
	struct perfmod_info *global = &perfmod_info;
	u64 partial_system_throttle_time = 0;
	int i;
	for_each_online_cpu (i) {
		struct core_info *cinfo = per_cpu_ptr (core_info, i);
		spin_lock (&cinfo->core_lock);
		partial_system_throttle_time += cinfo->core_throttle_duration;
		cinfo->core_throttle_duration = 0;
		spin_unlock (&cinfo->core_lock);
	}

	global->system_throttle_duration += partial_system_throttle_time;
	seq_printf (m, "System Throttle Time (Since Last Check): %lld\n", partial_system_throttle_time);
	return 0;
}

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

	if (!debugfs_create_file("reset_and_show_throttle_time", 0444, bwlockmod_dir, NULL, &bwlock_throttle_fops))
		goto fail;

	return 0;

fail:
	debugfs_remove_recursive (bwlockmod_dir);
	return -ENOMEM;
}
