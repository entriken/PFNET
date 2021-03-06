/** @file constr_REG_GEN.h
 *  @brief This file lists the constants and routines associated with the constraint of type REG_GEN.
 *
 * This file is part of PFNET.
 *
 * Copyright (c) 2015-2017, Tomas Tinoco De Rubira.
 *
 * PFNET is released under the BSD 2-clause license.
 */

#ifndef __CONSTR_REG_GEN_HEADER__
#define __CONSTR_REG_GEN_HEADER__

#include <math.h>
#include "constr.h"

// Parameters
#define CONSTR_REG_GEN_PARAM 1e-8
#define CONSTR_REG_GEN_MAX_YZ 1e8

// Function prototypes
Constr* CONSTR_REG_GEN_new(Net* net);
void CONSTR_REG_GEN_init(Constr* c);
void CONSTR_REG_GEN_count_step(Constr* c, Branch* br, int t);
void CONSTR_REG_GEN_allocate(Constr* c);
void CONSTR_REG_GEN_clear(Constr* c);
void CONSTR_REG_GEN_analyze_step(Constr* c, Branch* br, int t);
void CONSTR_REG_GEN_eval_step(Constr* c, Branch* br, int t, Vec* v, Vec* ve);
void CONSTR_REG_GEN_store_sens_step(Constr* c, Branch* br, int t, Vec* sA, Vec* sf, Vec* sGu, Vec* sGl);
void CONSTR_REG_GEN_free(Constr* c);

#endif
