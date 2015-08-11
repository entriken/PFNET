#***************************************************#
# This file is part of PFNET.                       #
#                                                   #
# Copyright (c) 2015, Tomas Tinoco De Rubira.       #
#                                                   #
# PFNET is released under the BSD 2-clause license. #
#***************************************************#

cdef extern from "pfnet/bus.h":

    ctypedef struct Bus
    ctypedef struct Gen
    ctypedef struct Load
    ctypedef struct Branch
    ctypedef struct Shunt
    ctypedef struct Vargen
    ctypedef double REAL
    
    cdef char BUS_VAR_VMAG
    cdef char BUS_VAR_VANG
    cdef char BUS_VAR_VDEV
    cdef char BUS_VAR_VVIO

    cdef char BUS_PROP_ANY
    cdef char BUS_PROP_SLACK
    cdef char BUS_PROP_REG_BY_GEN
    cdef char BUS_PROP_REG_BY_TRAN
    cdef char BUS_PROP_REG_BY_SHUNT
    cdef char BUS_PROP_NOT_REG_BY_GEN
    cdef char BUS_PROP_NOT_SLACK

    cdef char BUS_SENS_LARGEST
    cdef char BUS_SENS_P_BALANCE 
    cdef char BUS_SENS_Q_BALANCE 
    cdef char BUS_SENS_V_MAG_U_BOUND
    cdef char BUS_SENS_V_MAG_L_BOUND
    cdef char BUS_SENS_V_REG_BY_GEN
    cdef char BUS_SENS_V_REG_BY_TRAN
    cdef char BUS_SENS_V_REG_BY_SHUNT
    
    cdef char BUS_MIS_LARGEST
    cdef char BUS_MIS_ACTIVE
    cdef char BUS_MIS_REACTIVE

    int BUS_get_index(Bus* bus)
    int BUS_get_index_v_mag(Bus* bus)
    int BUS_get_index_v_ang(Bus* bus)
    int BUS_get_index_y(Bus* bus)
    int BUS_get_index_z(Bus* bus)
    int BUS_get_index_vl(Bus* bus)
    int BUS_get_index_vh(Bus* bus)
    int BUS_get_index_P(Bus* bus)
    int BUS_get_index_Q(Bus* bus)
    int BUS_get_number(Bus* bus)
    Gen* BUS_get_gen(Bus* bus)
    Gen* BUS_get_reg_gen(Bus* bus)
    Branch* BUS_get_reg_tran(Bus* bus)
    Shunt* BUS_get_reg_shunt(Bus* bus)
    Branch* BUS_get_branch_from(Bus* bus)
    Branch* BUS_get_branch_to(Bus* bus)
    Load* BUS_get_load(Bus* bus)
    Vargen* BUS_get_vargen(Bus* bus)
    int BUS_get_degree(Bus* bus)
    REAL BUS_get_total_gen_P(Bus* bus)
    REAL BUS_get_total_gen_Q(Bus* bus)
    REAL BUS_get_total_gen_Q_max(Bus* bus)
    REAL BUS_get_total_gen_Q_min(Bus* bus)
    REAL BUS_get_total_load_P(Bus* bus)
    REAL BUS_get_total_load_Q(Bus* bus)
    REAL BUS_get_total_shunt_g(Bus* bus)
    REAL BUS_get_total_shunt_b(Bus* bus)
    REAL BUS_get_v_mag(Bus* bus)
    REAL BUS_get_v_ang(Bus* bus)
    REAL BUS_get_v_set(Bus* bus)
    REAL BUS_get_v_max(Bus* bus)
    REAL BUS_get_v_min(Bus* bus)
    REAL BUS_get_P_mis(Bus* bus)
    REAL BUS_get_Q_mis(Bus* bus)
    REAL BUS_get_sens_P_balance(Bus* bus)
    REAL BUS_get_sens_Q_balance(Bus* bus)
    REAL BUS_get_sens_v_mag_u_bound(Bus* bus)
    REAL BUS_get_sens_v_mag_l_bound(Bus* bus)
    REAL BUS_get_sens_v_reg_by_gen(Bus* bus)
    REAL BUS_get_sens_v_reg_by_tran(Bus* bus)
    REAL BUS_get_sens_v_reg_by_shunt(Bus* bus)
    REAL BUS_get_largest_sens(Bus* bus)
    int BUS_get_largest_sens_type(Bus* bus)
    REAL BUS_get_largest_mis(Bus* bus)
    int BUS_get_largest_mis_type(Bus* bus)
    REAL BUS_get_quantity(Bus* bus, int qtype)
    Bus* BUS_get_next(Bus* bus)
    bint BUS_is_slack(Bus* bus)
    bint BUS_is_regulated_by_gen(Bus* bus)
    bint BUS_is_regulated_by_tran(Bus* bus)
    bint BUS_is_regulated_by_shunt(Bus* bus)
    bint BUS_has_flags(Bus* bus, char flag_type, char mask)
    Bus* BUS_new()
    void BUS_set_v_mag(Bus* bus, REAL v_mag)
    void BUS_set_v_ang(Bus* bus, REAL v_ang)
    void BUS_show(Bus* bus)
    
