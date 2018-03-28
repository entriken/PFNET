/** @file constr_LINPF.c
 *  @brief This file defines the data structure and routines associated with the constraint of type LINPF.
 *
 * This file is part of PFNET.
 *
 * Copyright (c) 2015, Tomas Tinoco De Rubira.
 *
 * PFNET is released under the BSD 2-clause license.
 */

#include <pfnet/constr_LINPF.h>
#include <pfnet/constr_ACPF.h>

Constr* CONSTR_LINPF_new(Net* net) {
  Constr* c = CONSTR_new(net);
  CONSTR_set_func_init(c, &CONSTR_LINPF_init);
  CONSTR_set_func_count_step(c, &CONSTR_LINPF_count_step);
  CONSTR_set_func_allocate(c, &CONSTR_LINPF_allocate);
  CONSTR_set_func_clear(c, &CONSTR_LINPF_clear);
  CONSTR_set_func_analyze_step(c, &CONSTR_LINPF_analyze_step);
  CONSTR_set_func_eval_step(c, &CONSTR_LINPF_eval_step);
  CONSTR_set_func_store_sens_step(c, &CONSTR_LINPF_store_sens_step);
  CONSTR_set_func_free(c, &CONSTR_LINPF_free);
  CONSTR_init(c);
  return c;
}

void CONSTR_LINPF_init(Constr* c) {

  // Init
  Constr* acpf = CONSTR_ACPF_new(CONSTR_get_network(c));
  CONSTR_set_name(c,"linearized AC power balance");
  CONSTR_set_data(c,(void*)acpf);
}

void CONSTR_LINPF_clear(Constr* c) {
  
  // ACPF
  Constr* acpf = (Constr*)CONSTR_get_data(c);
  CONSTR_clear(acpf);
}

void CONSTR_LINPF_count_step(Constr* c, Branch* br, int t) {

  // ACPF
  Constr* acpf = (Constr*)CONSTR_get_data(c);
  CONSTR_count_step(acpf,br,t);
}

void CONSTR_LINPF_allocate(Constr* c) {
  
  // Local variables
  Net* net;
  int num_vars;
  Constr* acpf;
  
  net = CONSTR_get_network(c);
  num_vars = NET_get_num_vars(net);
  acpf = (Constr*)CONSTR_get_data(c);

  // ACPF
  CONSTR_allocate(acpf);
   
  // A b (empty)
  CONSTR_set_A(c,CONSTR_get_J(acpf)); // temporary
  CONSTR_set_b(c,CONSTR_get_f(acpf)); // temporary

  // J f (empty)
  CONSTR_set_J(c,MAT_new(0,num_vars,0));
  CONSTR_set_f(c,VEC_new(0));

  // G l u (empty)
  CONSTR_set_G(c,MAT_new(0,num_vars,0));
  CONSTR_set_l(c,VEC_new(0));
  CONSTR_set_u(c,VEC_new(0));
}

void CONSTR_LINPF_analyze_step(Constr* c, Branch* br, int t) {

  // Local vars
  Constr* acpf;
  Net* net;
  Vec* f;
  Mat* J;
  Vec* x0;
  Vec* b;
  int T;

  // Number of periods
  T = BRANCH_get_num_periods(br);

  // Net
  net = CONSTR_get_network(c);

  // ACPF
  acpf = (Constr*)CONSTR_get_data(c);
  CONSTR_analyze_step(acpf,br,t);

  // Done 
  if ((t == T-1) && (BRANCH_get_index(br) == NET_get_num_branches(net)-1)) {
    x0 = NET_get_var_values(net,CURRENT);
    CONSTR_eval(acpf,x0,NULL);
    J = CONSTR_get_J(acpf);
    f = CONSTR_get_f(acpf);
    b = MAT_rmul_by_vec(J,x0);
    VEC_sub_inplace(b,f);
    CONSTR_set_b(c,b);
    CONSTR_set_A(c,MAT_copy(J));
  }
}

void CONSTR_LINPF_eval_step(Constr* c, Branch* br, int t, Vec* values, Vec* values_extra) {
  // Nothing
}

void CONSTR_LINPF_store_sens_step(Constr* c, Branch* br, int t, Vec* sA, Vec* sf, Vec* sGu, Vec* sGl) {
  // Nothing for now
}
 
void CONSTR_LINPF_free(Constr* c) {
  
  // ACPF
  Constr* acpf = (Constr*)CONSTR_get_data(c);
  CONSTR_del(acpf);
  CONSTR_set_data(c,NULL);
}
