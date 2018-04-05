/**
 * FILE		: perfmod.h
 * BRIEF	: Declarations and prototypes for PERFMOD kernel module
 *
 * Copyright (C) 2017 Waqar Ali <wali@ku.edu>
 *
 * This file is distributed under the University of Kansas Open Source
 * License. See LICENSE.TXT for details.
 *
 */

#ifndef __BWLOCKMOD_H__
#define __BWLOCKMOD_H__

/**************************************************************************
 * Local Function Prototypes
 **************************************************************************/
int init_modules (void);
void cleanup_module (void);
int lazy_init_thread (void *);

#endif /* __BWLOCKMOD_H__ */
