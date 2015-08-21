#***************************************************#
# This file is part of PFNET.                       #
#                                                   #
# Copyright (c) 2015, Tomas Tinoco De Rubira.       #
#                                                   #
# PFNET is released under the BSD 2-clause license. #
#***************************************************#

cimport cvec
cimport cbus
cimport cbranch
cimport cgen
cimport cload
cimport cshunt

cdef extern from "pfnet/net.h":

    ctypedef struct Net
    ctypedef double REAL
 
    void NET_adjust_generators(Net* net)
    cbus.Bus* NET_bus_hash_find(Net* net, int number)
    void NET_clear_flags(Net* net)
    void NET_clear_properties(Net* net)
    void NET_clear_sensitivities(Net* net)
    cbus.Bus* NET_create_sorted_bus_list(Net* net, int sort_by)
    void NET_del(Net* net)
    REAL NET_get_base_power(Net* net)
    cbus.Bus* NET_get_bus(Net* net, int index)
    cbranch.Branch* NET_get_branch(Net* net, int index)
    char* NET_get_error_string(Net* net)
    cgen.Gen* NET_get_gen(Net* net, int index)
    cshunt.Shunt* NET_get_shunt(Net* net, int index)
    cload.Load* NET_get_load(Net* net, int index)
    int NET_get_num_buses(Net* net)
    int NET_get_num_slack_buses(Net* net)
    int NET_get_num_buses_reg_by_gen(Net* net)
    int NET_get_num_buses_reg_by_tran(Net* net)
    int NET_get_num_buses_reg_by_tran_only(Net* net)
    int NET_get_num_buses_reg_by_shunt(Net* net)
    int NET_get_num_buses_reg_by_shunt_only(Net* net)
    int NET_get_num_branches(Net* net)
    int NET_get_num_fixed_trans(Net* net)
    int NET_get_num_lines(Net* net)
    int NET_get_num_phase_shifters(Net* net)
    int NET_get_num_tap_changers(Net* net)
    int NET_get_num_tap_changers_v(Net* net)
    int NET_get_num_tap_changers_Q(Net* net)
    int NET_get_num_gens(Net* net)
    int NET_get_num_reg_gens(Net* net)
    int NET_get_num_slack_gens(Net* net)
    int NET_get_num_loads(Net* net)
    int NET_get_num_shunts(Net* net)
    int NET_get_num_fixed_shunts(Net* net)
    int NET_get_num_switched_shunts(Net* net)
    int NET_get_num_vars(Net* net)
    int NET_get_num_fixed(Net* net)
    int NET_get_num_bounded(Net* net)
    int NET_get_num_sparse(Net* net)
    REAL NET_get_bus_v_max(Net* net)
    REAL NET_get_bus_v_min(Net* net)
    REAL NET_get_bus_v_vio(Net* net)
    REAL NET_get_bus_P_mis(Net* net)
    REAL NET_get_bus_Q_mis(Net* net)
    REAL NET_get_gen_v_dev(Net* net)
    REAL NET_get_gen_Q_vio(Net* net)
    REAL NET_get_gen_P_vio(Net* net)
    REAL NET_get_tran_v_vio(Net* net)
    REAL NET_get_tran_r_vio(Net* net)
    REAL NET_get_tran_p_vio(Net* net)
    REAL NET_get_shunt_v_vio(Net* net)
    REAL NET_get_shunt_b_vio(Net* net)
    int NET_get_num_actions(Net* net)
    cvec.Vec* NET_get_var_values(Net* net)
    bint NET_has_error(Net* net)
    void NET_load(Net* net, char* filename)
    Net* NET_new()
    void NET_set_flags(Net* net, char obj_type, char flag_mask, char prop_mask, char val_mask)
    void NET_set_var_values(Net* net, cvec.Vec* values)
    void NET_show_components(Net* net)
    void NET_show_properties(Net* net)
    void NET_show_buses(Net* net, int number, int sort_by)
    void NET_update_properties(Net* net, cvec.Vec* values)
    void NET_update_set_points(Net* net)
    
     
          