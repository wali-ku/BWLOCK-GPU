/* This files contains wrappers for some of the CUDA runtime API rotuines. It
 * should be compiled as a shared library and used via LD_PRELOAD to capture
 * calls to CUDA runtime API invocations of a GPU application
 *
 * Author	: Waqar Ali (wali@ku.edu)
 *
 * ACKNOWLEDGEMENT
 * The code in the following git repository was used to aid in this effort:
 * 	https://github.com/nchong/cudahook
 */

#include <stdbool.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>

/* CPP Headers */
#include <algorithm>
#include <iostream>
#include <vector>
#include <string>
#include <map>

/* Include CUDA header */
#include <cuda_runtime.h>
#include <vector_types.h>

#define SYS_BWLOCK			245
#define K1				1000UL
#define M1				(K1 * K1)
#define G1				(K1 * K1 * K1)
#define PRINT_LINE(field, value)	fprintf (stderr, "%40s : %d\n", field, value)

#define RECORD_TIMESTAMP()						\
do {									\
	struct timespec tv;						\
	clock_gettime (CLOCK_REALTIME, &tv);				\
	timestamp = (uint64_t)(tv.tv_sec * G1 + tv.tv_nsec);		\
} while (0);

#define UPDATE_ACTIVE_STREAMS(stream)					\
do {									\
	if (std::find (active_streams.begin (),				\
		       active_streams.end (),				\
		       stream) == active_streams.end ())		\
		active_streams.push_back (stream);			\
} while (0);

#define GET_SYMBOL(name)						\
do {									\
	if (!orig_##name)						\
		orig_##name = (name##_t) dlsym (RTLD_NEXT, #name);	\
} while (0);

#define GET_LOCK()							\
do {									\
	if (!locked) {							\
		syscall (SYS_BWLOCK, NULL, 1);				\
		locked = true;						\
	}								\
} while (0);

#define REL_LOCK()							\
do {									\
	if (locked) {							\
		syscall (SYS_BWLOCK, NULL, 0);				\
		active_streams.clear ();				\
		locked = false;						\
	} else								\
		fprintf (stderr, "[WARNING] Possibly erroneous unlock"	\
				 " attempt\n");				\
} while (0);

static std::vector<cudaStream_t> active_streams;
static int poi = 0;
static uint64_t timestamp;

static int memcpy_limit = 1024;
static bool locked = false;

static int stats_memcpy_amount = 0;
static int stats_memcpy_lock_amount = 0;
static int stats_memcpy_async_amount = 0;

static int stats_thread_sync_count = 0;
static int stats_device_sync_count = 0;
static int stats_stream_sync_count = 0;

static int stats_memcpy_count = 0;
static int stats_memcpy_async_count = 0;
static int stats_kern_launch_count = 0;

static uint64_t time_copy_duration = 0;
static uint64_t time_copy_async_duration = 0;
static uint64_t time_kern_duration = 0;
static uint64_t time_total_copy_duration = 0;
static uint64_t time_total_copy_async_duration = 0;
static uint64_t time_total_kern_duration = 0;

/* Create typedefs to the target CUDA APIs */
typedef cudaError_t	(*cudaMemcpyAsync_t)(void*, const void*, size_t, cudaMemcpyKind, cudaStream_t);
typedef cudaError_t	(*cudaMemcpy_t)(void*, const void*, size_t, cudaMemcpyKind);
typedef cudaError_t	(*cudaStreamSynchronize_t)(cudaStream_t);
typedef cudaError_t	(*cudaDeviceSynchronize_t)(void);
typedef cudaError_t	(*cudaThreadSynchronize_t)(void);
typedef cudaError_t	(*cudaLaunch_t)(const void*);

typedef cudaError_t	(*cudaConfigureCall_t)(dim3, dim3, size_t, cudaStream_t);
typedef cudaError_t	(*cudaSetupArgument_t)(const void*, size_t, size_t);
typedef cudaError_t	(*cudaEventSynchronize_t)(cudaEvent_t event);

/* Statically declare function pointers for real CUDA APIs */
static cudaMemcpyAsync_t	orig_cudaMemcpyAsync = NULL;
static cudaMemcpy_t		orig_cudaMemcpy = NULL;
static cudaStreamSynchronize_t	orig_cudaStreamSynchronize = NULL;
static cudaDeviceSynchronize_t	orig_cudaDeviceSynchronize = NULL;
static cudaThreadSynchronize_t	orig_cudaThreadSynchronize = NULL;
static cudaLaunch_t 		orig_cudaLaunch = NULL;

static cudaConfigureCall_t 	orig_cudaConfigureCall = NULL;
static cudaSetupArgument_t	orig_cudaSetupArgument = NULL;
static cudaEventSynchronize_t	orig_cudaEventSynchronize = NULL;

void print_stats (void)
{
	PRINT_LINE ("Kernel Launches", 				stats_kern_launch_count);
	PRINT_LINE ("Device Synchronization Count", 		stats_device_sync_count);
	PRINT_LINE ("Thread Synchronization Count", 		stats_thread_sync_count);
	PRINT_LINE ("Stream Synchronization Count", 		stats_stream_sync_count);
	PRINT_LINE ("Synchronous Memory Copies", 		stats_memcpy_count);
	PRINT_LINE ("Asynchronous Memory Copies", 		stats_memcpy_async_count);
	PRINT_LINE ("Synchronous Copy Amount (Bytes)", 		stats_memcpy_amount);
	PRINT_LINE ("Locked Synchronous Copy Amount (Bytes)", 	stats_memcpy_lock_amount);
	PRINT_LINE ("Asynchronous Copy Amount (Bytes)", 	stats_memcpy_async_amount);

	return;
}

uint64_t get_elapsed(struct timespec *start, struct timespec *end)
{
	uint64_t dur;
	if (start->tv_nsec > end->tv_nsec)
		dur = (uint64_t)(end->tv_sec - 1 - start->tv_sec) * G1 +
			(G1 + end->tv_nsec - start->tv_nsec);
	else
		dur = (uint64_t)(end->tv_sec - start->tv_sec) * G1 +
			(end->tv_nsec - start->tv_nsec);

	return (dur / K1);
}

extern "C"
cudaError_t cudaConfigureCall (dim3 gridDim,
			       dim3 blockDim,
			       size_t sharedMem,
			       cudaStream_t stream)
{
	GET_SYMBOL (cudaConfigureCall);
	UPDATE_ACTIVE_STREAMS (stream);

	return orig_cudaConfigureCall (gridDim, blockDim, sharedMem, stream);
}

extern "C"
cudaError_t cudaMemcpy (void *dst,
			const void *src,
			size_t count,
			cudaMemcpyKind kind)
{
	cudaError_t status;
	GET_SYMBOL (cudaMemcpy);

	if (!locked && ((int)count > memcpy_limit)) {
		syscall (SYS_BWLOCK, NULL, 1);
		status = orig_cudaMemcpy (dst, src, count, kind);
		syscall (SYS_BWLOCK, NULL, 0);
	} else
		status = orig_cudaMemcpy (dst, src, count, kind);
	
	stats_memcpy_count++;
	stats_memcpy_amount += (int)count;
	return status;
}

extern "C"
cudaError_t cudaMemcpyAsync (void *dst,
			     const void *src,
			     size_t count,
			     cudaMemcpyKind kind,
			     cudaStream_t stream)
{
	GET_SYMBOL (cudaMemcpyAsync);
	UPDATE_ACTIVE_STREAMS (stream);
	GET_LOCK ();

	stats_memcpy_async_count++;
	stats_memcpy_async_amount += (int)count;
	return orig_cudaMemcpyAsync (dst, src, count, kind, stream);
}

extern "C"
cudaError_t cudaLaunch (const void *func)
{
	GET_SYMBOL (cudaLaunch);
	GET_LOCK ();

	stats_kern_launch_count++;
	return orig_cudaLaunch (func);
}

extern "C"
cudaError_t cudaThreadSynchronize (void)
{
	cudaError_t ret = cudaSuccess;
	GET_SYMBOL (cudaThreadSynchronize);

	ret = orig_cudaThreadSynchronize ();
	REL_LOCK ();

	stats_thread_sync_count++;
	print_stats ();
	return ret;
}

extern "C"
cudaError_t cudaDeviceSynchronize (void)
{
	cudaError_t ret = cudaSuccess;
	GET_SYMBOL (cudaDeviceSynchronize);

	ret = orig_cudaDeviceSynchronize ();
	REL_LOCK ();

	stats_device_sync_count++;
	return ret;
}

extern "C"
cudaError_t cudaStreamSynchronize (cudaStream_t stream)
{
	cudaError_t ret = cudaSuccess;
	GET_SYMBOL (cudaStreamSynchronize);

	ret = orig_cudaStreamSynchronize (stream);
	active_streams.erase (std::remove (active_streams.begin (), active_streams.end (), stream), active_streams.end ());
	if (active_streams.empty ())
		REL_LOCK ();
		
	stats_stream_sync_count++;
	return ret;
}
