#include <sys/syscall.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#define SYS_bwlock	245
#define K1		1000ULL
#define M1		(K1 * K1)
#define G1		(K1 * K1 * K1)

uint64_t get_elapsed(struct timespec *start, struct timespec *end)
{
	uint64_t dur;
	if (start->tv_nsec > end->tv_nsec)
		dur = (uint64_t)(end->tv_sec - 1 - start->tv_sec) * G1 +
			(G1 + end->tv_nsec - start->tv_nsec);
	else
		dur = (uint64_t)(end->tv_sec - start->tv_sec) * G1 +
			(end->tv_nsec - start->tv_nsec);

	return dur;
}

void block_exec (int dur_in_secs, bool lock, struct timespec *finish)
{
	struct timespec start, end;
	pid_t my_pid = getpid ();
	uint64_t tmpdiff;

	if (lock) syscall(SYS_bwlock, my_pid, 1);
	clock_gettime (CLOCK_PROCESS_CPUTIME_ID, &start);	
	do {
		clock_gettime (CLOCK_PROCESS_CPUTIME_ID, &end);
		tmpdiff = get_elapsed (&start, &end);
	} while (tmpdiff < (dur_in_secs * G1));
	clock_gettime (CLOCK_REALTIME, finish);	
	if (lock) syscall(SYS_bwlock, my_pid, 0);

	return;
}

int main(int argc, char **argv)
{
	int sleep_duration = strtol (argv[2], NULL, 10);
	int exec_duration = strtol (argv[3], NULL, 10);
	bool lock = (strtol (argv[4], NULL, 2) == 1);
	struct timespec start, end;
	uint64_t tmpdiff;
	
	printf ("Task-%s started!\n", argv[1]);
	clock_gettime (CLOCK_REALTIME, &start);	
	sleep (sleep_duration);
	block_exec (exec_duration, lock, &end);

	tmpdiff = get_elapsed (&start, &end);
	printf ("Task-%s took %d seconds\n", argv[1], (int)(tmpdiff / G1));

	return 0;
}
