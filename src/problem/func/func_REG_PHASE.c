/** @file func_REG_PHASE.c
 *  @brief This file defines the data structure and routines associated with the function of type REG_PHASE.
 *
 * This file is part of PFNET.
 *
 * Copyright (c) 2015-2017, Tomas Tinoco De Rubira.
 *
 * PFNET is released under the BSD 2-clause license.
 */

#include <pfnet/func_REG_PHASE.h>

Func* FUNC_REG_PHASE_new(REAL weight, Net* net) {
  Func* f = FUNC_new(weight,net);
  FUNC_set_func_init(f, &FUNC_REG_PHASE_init);
  FUNC_set_func_count_step(f, &FUNC_REG_PHASE_count_step);
  FUNC_set_func_allocate(f, &FUNC_REG_PHASE_allocate);
  FUNC_set_func_clear(f, &FUNC_REG_PHASE_clear);
  FUNC_set_func_analyze_step(f, &FUNC_REG_PHASE_analyze_step);
  FUNC_set_func_eval_step(f, &FUNC_REG_PHASE_eval_step);
  FUNC_set_func_free(f, &FUNC_REG_PHASE_free);
  FUNC_init(f);
  return f;
}

void FUNC_REG_PHASE_init(Func* f) {
  
  FUNC_set_name(f,"phase shift regularization");
}

void FUNC_REG_PHASE_clear(Func* f) {
  
  // phi
  FUNC_set_phi(f,0);
  
  // gphi
  VEC_set_zero(FUNC_get_gphi(f));
  
  // Hphi
  // Constant so not clear it
  
  // Counter
  FUNC_set_Hphi_nnz(f,0);
}

void FUNC_REG_PHASE_count_step(Func* f, Branch* br, int t) {

  // Local variables
  int* Hphi_nnz;

  // Constr data
  Hphi_nnz = FUNC_get_Hphi_nnz_ptr(f);

  // Check pointer
  if (!Hphi_nnz)
    return;

  // Check outage
  if (BRANCH_is_on_outage(br))
    return;
  
  if (BRANCH_has_flags(br,FLAG_VARS,BRANCH_VAR_PHASE)) // phase var
    (*Hphi_nnz)++;
}

void FUNC_REG_PHASE_allocate(Func* f) {
  
  // Local variables
  int num_vars;
  int Hphi_nnz;
  
  num_vars = NET_get_num_vars(FUNC_get_network(f));
  Hphi_nnz = FUNC_get_Hphi_nnz(f);

  // gphi
  FUNC_set_gphi(f,VEC_new(num_vars));

  // Hphi
  FUNC_set_Hphi(f,MAT_new(num_vars,
			  num_vars,
			  Hphi_nnz));
}

void FUNC_REG_PHASE_analyze_step(Func* f, Branch* br, int t) {

  // Local variables
  int* Hphi_nnz;
  Mat* H;
  REAL dp;

  // Constr data
  H = FUNC_get_Hphi(f);
  Hphi_nnz = FUNC_get_Hphi_nnz_ptr(f);

  // Check pointer
  if (!Hphi_nnz)
    return;

  // Check outage
  if (BRANCH_is_on_outage(br))
    return;

  // Normalization factor
  dp = BRANCH_get_phase_max(br)-BRANCH_get_phase_min(br);
  if (dp < FUNC_REG_PHASE_PARAM)
    dp = FUNC_REG_PHASE_PARAM;
  
  if (BRANCH_has_flags(br,FLAG_VARS,BRANCH_VAR_PHASE)) { // phase var
    MAT_set_i(H,*Hphi_nnz,BRANCH_get_index_phase(br,t));
    MAT_set_j(H,*Hphi_nnz,BRANCH_get_index_phase(br,t));
    MAT_set_d(H,*Hphi_nnz,1./(dp*dp));
    (*Hphi_nnz)++;
  }
}

void FUNC_REG_PHASE_eval_step(Func* f, Branch* br, int t, Vec* var_values) {

  // Local variables
  REAL* phi;
  REAL* gphi;
  REAL p;
  REAL dp;
  REAL p0;

  // Constr data
  phi = FUNC_get_phi_ptr(f);
  gphi = VEC_get_data(FUNC_get_gphi(f));

  // Check pointers
  if (!phi || !gphi)
    return;

  // Check outage
  if (BRANCH_is_on_outage(br))
    return;
  
  // Normalizatin factor
  dp = BRANCH_get_phase_max(br)-BRANCH_get_phase_min(br);
  if (dp < FUNC_REG_PHASE_PARAM)
    dp = FUNC_REG_PHASE_PARAM;

  if (BRANCH_has_flags(br,FLAG_VARS,BRANCH_VAR_PHASE)) { // phase var    
    
    p0 = BRANCH_get_phase(br,t);
    p = VEC_get(var_values,BRANCH_get_index_phase(br,t));
    (*phi) += 0.5*pow((p-p0)/dp,2.);
    gphi[BRANCH_get_index_phase(br,t)] = (p-p0)/(dp*dp);
  }
  else {
    // nothing because p0-p0 = 0
  }
}
    
void FUNC_REG_PHASE_free(Func* f) {
  // Nothing
}
