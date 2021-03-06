/** @file func_GEN_COST.h
 *  @brief This file lists the constants and routines associated with the function of type GEN_COST.
 *
 * This file is part of PFNET.
 *
 * Copyright (c) 2015-2017, Tomas Tinoco De Rubira.
 *
 * PFNET is released under the BSD 2-clause license.
 */

#ifndef __FUNC_GEN_COST_HEADER__
#define __FUNC_GEN_COST_HEADER__

#include <math.h>
#include "func.h"

// Function prototypes
Func* FUNC_GEN_COST_new(REAL weight, Net* net);
void FUNC_GEN_COST_init(Func* f);
void FUNC_GEN_COST_count_step(Func* f, Branch* br, int t);
void FUNC_GEN_COST_allocate(Func* f);
void FUNC_GEN_COST_clear(Func* f);
void FUNC_GEN_COST_analyze_step(Func* f, Branch* br, int t);
void FUNC_GEN_COST_eval_step(Func* f, Branch* br, int t, Vec* v);
void FUNC_GEN_COST_free(Func* f);

#endif
