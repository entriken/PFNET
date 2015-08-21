#cython: embedsignature=True

#***************************************************#
# This file is part of PFNET.                       #
#                                                   #
# Copyright (c) 2015, Tomas Tinoco De Rubira.       #
#                                                   #
# PFNET is released under the BSD 2-clause license. #
#***************************************************#

cimport cflags
cimport cobjs
cimport cvec
cimport cmat
cimport cgen
cimport cshunt
cimport cbus
cimport cbranch
cimport cload
cimport cnet
cimport cgraph
cimport cconstr
cimport cfunc
cimport cheur
cimport cprob

import numpy as np
cimport numpy as np

from subprocess import call
from scipy import misc
import tempfile

from scipy.sparse import coo_matrix, bmat

np.import_array()

# Constants
###########

# Objects
OBJ_BUS = cobjs.OBJ_BUS
OBJ_GEN = cobjs.OBJ_GEN
OBJ_BRANCH = cobjs.OBJ_BRANCH
OBJ_SHUNT = cobjs.OBJ_SHUNT

# Flags
FLAG_VARS = cflags.FLAG_VARS
FLAG_FIXED = cflags.FLAG_FIXED
FLAG_BOUNDED = cflags.FLAG_BOUNDED
FLAG_SPARSE = cflags.FLAG_SPARSE

# Vector
########

cdef Vector(cvec.Vec* v):
     cdef np.npy_intp shape[1]
     if v is not NULL:
         shape[0] = <np.npy_intp> cvec.VEC_get_size(v)
         return np.PyArray_SimpleNewFromData(1,shape,np.NPY_DOUBLE,cvec.VEC_get_data(v))
     else:
         return np.zeros(0)

# Matrix
########

cdef Matrix(cmat.Mat* m):
     cdef np.npy_intp shape[1]
     if m is not NULL:
         shape[0] = <np.npy_intp> cmat.MAT_get_nnz(m)
         size1 = cmat.MAT_get_size1(m)
         size2 = cmat.MAT_get_size2(m)
         row = np.PyArray_SimpleNewFromData(1,shape,np.NPY_INT,cmat.MAT_get_row_array(m))
         col = np.PyArray_SimpleNewFromData(1,shape,np.NPY_INT,cmat.MAT_get_col_array(m))
         data = np.PyArray_SimpleNewFromData(1,shape,np.NPY_DOUBLE,cmat.MAT_get_data_array(m))
         return coo_matrix((data,(row,col)),shape=(size1,size2))
     else:
         return coo_matrix(([],([],[])),shape=(0,0))

# Bus
#####

BUS_PROP_ANY = cbus.BUS_PROP_ANY
BUS_PROP_SLACK = cbus.BUS_PROP_SLACK
BUS_PROP_REG_BY_GEN = cbus.BUS_PROP_REG_BY_GEN
BUS_PROP_REG_BY_TRAN = cbus.BUS_PROP_REG_BY_TRAN
BUS_PROP_REG_BY_SHUNT = cbus.BUS_PROP_REG_BY_SHUNT
BUS_PROP_NOT_REG_BY_GEN = cbus.BUS_PROP_NOT_REG_BY_GEN
BUS_PROP_NOT_SLACK = cbus.BUS_PROP_NOT_SLACK

# Variables
BUS_VAR_VMAG = cbus.BUS_VAR_VMAG
BUS_VAR_VANG = cbus.BUS_VAR_VANG
BUS_VAR_VDEV = cbus.BUS_VAR_VDEV
BUS_VAR_VVIO = cbus.BUS_VAR_VVIO

# Sensitivities
BUS_SENS_LARGEST = cbus.BUS_SENS_LARGEST
BUS_SENS_P_BALANCE = cbus.BUS_SENS_P_BALANCE
BUS_SENS_Q_BALANCE = cbus.BUS_SENS_Q_BALANCE
BUS_SENS_V_MAG_U_BOUND = cbus.BUS_SENS_V_MAG_U_BOUND
BUS_SENS_V_MAG_L_BOUND = cbus.BUS_SENS_V_MAG_L_BOUND
BUS_SENS_V_REG_BY_GEN = cbus.BUS_SENS_V_REG_BY_GEN
BUS_SENS_V_REG_BY_TRAN = cbus.BUS_SENS_V_REG_BY_TRAN
BUS_SENS_V_REG_BY_SHUNT = cbus.BUS_SENS_V_REG_BY_SHUNT
    
# Mismatches
BUS_MIS_LARGEST = cbus.BUS_MIS_LARGEST
BUS_MIS_ACTIVE = cbus.BUS_MIS_ACTIVE
BUS_MIS_REACTIVE = cbus.BUS_MIS_REACTIVE

class BusError(Exception):
    """
    Bus error exception.
    """
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Bus:
    """
    Bus class.
    """
    
    cdef cbus.Bus* _c_bus

    def __init__(self,alloc=True):
        """
        Bus class.
        
        Parameters
        ----------
        alloc : {``True``, ``False``}
        """
        
        pass

    def __cinit__(self,alloc=True):

        if alloc:
            self._c_bus = cbus.BUS_new()
        else:
            self._c_bus = NULL

    def is_slack(self):
        """
        Determines whether the bus is a slack bus.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbus.BUS_is_slack(self._c_bus)

    def is_regulated_by_gen(self):
        """
        Determines whether the bus is regulated by a generator.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbus.BUS_is_regulated_by_gen(self._c_bus)

    def is_regulated_by_tran(self):
        """
        Determines whether the bus is regulated by a transformer.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbus.BUS_is_regulated_by_tran(self._c_bus)

    def is_regulated_by_shunt(self):
        """
        Determines whether the bus is regulated by a shunt device.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbus.BUS_is_regulated_by_shunt(self._c_bus)

    def has_flags(self,fmask,vmask):
        """
        Determines whether the bus has the flags associated with 
        certain quantities set.

        Parameters
        ----------
        fmask : int (:ref:`ref_net_flag`)
        vmask : int (:ref:`ref_bus_var`)

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbus.BUS_has_flags(self._c_bus,fmask,vmask)

    def get_largest_sens(self):
        """
        Gets the bus sensitivity of largest absolute value.
        
        Returns
        -------
        sens : float
        """

        return cbus.BUS_get_largest_sens(self._c_bus)

    def get_largest_sens_type(self):
        """
        Gets the type of bus sensitivity of largest absolute value.

        Returns
        -------
        type : int
        """

        return cbus.BUS_get_largest_sens_type(self._c_bus)

    def get_largest_mis(self):
        """
        Gets the bus power mismatch of largest absolute value.

        Returns
        -------
        mis : float
        """

        return cbus.BUS_get_largest_mis(self._c_bus)

    def get_largest_mis_type(self):
        """
        Gets the type of bus power mismatch of largest absolute value.

        Returns
        -------
        type : int
        """

        return cbus.BUS_get_largest_mis_type(self._c_bus)

    def get_quantity(self,type):
        """
        Gets the bus quantity of the given type. 

        Parameters
        ----------
        type : int (:ref:`ref_bus_sens`:, :ref:`ref_bus_mis`)

        Returns
        -------
        value : float
        """

        return cbus.BUS_get_quantity(self._c_bus,type)

    def get_total_gen_P(self):
        """
        Gets the total active power injected by generators
        connected to this bus.

        Returns
        -------
        P : float
        """

        return cbus.BUS_get_total_gen_P(self._c_bus)

    def get_total_gen_Q(self):
        """
        Gets the total reactive power injected by generators
        connected to this bus.

        Returns
        -------
        Q : float
        """

        return cbus.BUS_get_total_gen_Q(self._c_bus)

    def get_total_gen_Q_max(self):
        """ 
        Gets the largest total reactive power that can be 
        injected by generators connected to this bus.

        Returns
        -------
        Q_max : float
        """

        return cbus.BUS_get_total_gen_Q_max(self._c_bus)

    def get_total_gen_Q_min(self):
        """
        Gets the smallest total reactive power that can be 
        injected by generators connected to this bus.

        Returns
        -------
        Q_min : float
        """

        return cbus.BUS_get_total_gen_Q_min(self._c_bus)

    def get_total_load_P(self):
        """ 
        Gets the total active power consumed by loads
        connected to this bus.

        Returns
        -------
        P : float
        """

        return cbus.BUS_get_total_load_P(self._c_bus)

    def get_total_load_Q(self):
        """
        Gets the total reactive power consumed by loads
        connected to this bus.

        Returns
        -------
        Q : float
        """

        return cbus.BUS_get_total_load_Q(self._c_bus)

    def get_total_shunt_g(self):
        """ 
        Gets the combined conductance of shunt devices 
        connected to this bus.

        Returns
        -------
        g : float
        """

        return cbus.BUS_get_total_shunt_g(self._c_bus)

    def get_total_shunt_b(self):
        """
        Gets the combined susceptance of shunt devices 
        connected to this bus.

        Returns
        -------
        b : float
        """

        return cbus.BUS_get_total_shunt_b(self._c_bus)
    
    def show(self):
        """
        Shows bus properties.
        """
        cbus.BUS_show(self._c_bus)

    def __richcmp__(self,other,op):
        """
        Compares two buses.

        Parameters
        ----------
        other : Bus
        op : comparison type

        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        if op == 2:
            return isinstance(other,Bus) and self.index == other.index
        elif op == 3:
            return (not isinstance(other,Bus)) or self.index != other.index
        else:
            return False

    property index:
        """ Bus index (int). """
        def __get__(self): return cbus.BUS_get_index(self._c_bus)

    property index_v_mag: 
        """ Index of voltage magnitude variable (int). """
        def __get__(self): return cbus.BUS_get_index_v_mag(self._c_bus)

    property index_v_ang:
        """ Index of voltage angle variable (int). """
        def __get__(self): return cbus.BUS_get_index_v_ang(self._c_bus)

    property index_y:
        """ Index of voltage magnitude positive deviation variable (int). """
        def __get__(self): return cbus.BUS_get_index_y(self._c_bus)

    property index_z:
        """ Index of voltage magnitude negative deviation variable (int). """
        def __get__(self): return cbus.BUS_get_index_z(self._c_bus)

    property index_vl:
        """ Index of voltage low limit violation variable (int). """
        def __get__(self): return cbus.BUS_get_index_vl(self._c_bus)

    property index_vh:
        """ Index of voltage high limit violation variable (int). """
        def __get__(self): return cbus.BUS_get_index_vh(self._c_bus)

    property index_P:
        """ Index of bus active power mismatch (int). """
        def __get__(self): return cbus.BUS_get_index_P(self._c_bus)

    property index_Q:
        """ Index for bus reactive power mismatch (int). """
        def __get__(self): return cbus.BUS_get_index_Q(self._c_bus)

    property number:
        """ Bus number (int). """
        def __get__(self): return cbus.BUS_get_number(self._c_bus)

    property degree:
        """ Bus degree (number of incident branches) (float). """
        def __get__(self): return cbus.BUS_get_degree(self._c_bus)    

    property v_mag:
        """ Bus volatge magnitude (p.u. bus base kv) (float). """
        def __get__(self): return cbus.BUS_get_v_mag(self._c_bus)
        def __set__(self,value): cbus.BUS_set_v_mag(self._c_bus,value)

    property v_ang:
        """ Bus voltage angle (radians) (float). """
        def __get__(self): return cbus.BUS_get_v_ang(self._c_bus)
        def __set__(self,value): cbus.BUS_set_v_ang(self._c_bus,value)

    property v_set:
        """ Bus voltage set point (p.u. bus base kv) (float). Equals one if bus is not regulated by a generator. """
        def __get__(self): return cbus.BUS_get_v_set(self._c_bus)

    property v_max:
        """ Bus volatge upper bound (p.u. bus base kv) (float). """
        def __get__(self): return cbus.BUS_get_v_max(self._c_bus)

    property v_min:
        """ Bus voltage lower bound (p.u. bus base kv) (float). """
        def __get__(self): return cbus.BUS_get_v_min(self._c_bus)

    property P_mis:
        """ Bus active power mismatch (p.u. system base MVA) (float). """
        def __get__(self): return cbus.BUS_get_P_mis(self._c_bus)

    property Q_mis:
        """ Bus reactive power mismatch (p.u. system base MVA) (float). """
        def __get__(self): return cbus.BUS_get_Q_mis(self._c_bus)

    property sens_P_balance:
        """ Objective function sensitivity with respect to bus active power balance (float). """
        def __get__(self): return cbus.BUS_get_sens_P_balance(self._c_bus)

    property sens_Q_balance:
        """ Objective function sensitivity with respect to bus reactive power balance (float). """
        def __get__(self): return cbus.BUS_get_sens_Q_balance(self._c_bus)

    property sens_v_mag_u_bound:
        """ Objective function sensitivity with respect to bus upper voltage limit (float). """
        def __get__(self): return cbus.BUS_get_sens_v_mag_u_bound(self._c_bus)

    property sens_v_mag_l_bound:
        """ Objective function sensitivity with respect to bus lower voltage limit (float). """
        def __get__(self): return cbus.BUS_get_sens_v_mag_l_bound(self._c_bus)

    property sens_v_reg_by_gen:
        """ Objective function sensitivity with respect to bus voltage regulation by generators (float). """
        def __get__(self): return cbus.BUS_get_sens_v_reg_by_gen(self._c_bus)

    property sens_v_reg_by_tran:
        """ Objective function sensitivity with respect to bus voltage regulation by transformers (float). """
        def __get__(self): return cbus.BUS_get_sens_v_reg_by_tran(self._c_bus)

    property sens_v_reg_by_shunt:
        """ Objective function sensitivity with respect to bus voltage regulation by shunts (float). """
        def __get__(self): return cbus.BUS_get_sens_v_reg_by_shunt(self._c_bus)

    property gens:
        """ List of :class:`generators <pfnet.Generator>` connected to this bus (list). """
        def __get__(self):
            gens = []
            cdef cgen.Gen* g = cbus.BUS_get_gen(self._c_bus)
            while g is not NULL:
                gens.append(new_Generator(g))
                g = cgen.GEN_get_next(g)
            return gens

    property reg_gens: 
        """ List of :class:`generators <pfnet.Generator>` regulating the voltage magnitude of this bus (list). """
        def __get__(self):
            reg_gens = []
            cdef cgen.Gen* g = cbus.BUS_get_reg_gen(self._c_bus)
            while g is not NULL:
                reg_gens.append(new_Generator(g))
                g = cgen.GEN_get_reg_next(g)
            return reg_gens

    property reg_trans:
        """ List of :class:`tap-changing transformers <pfnet.Branch>` regulating the voltage magnitude of this bus (list). """
        def __get__(self):
            reg_trans = []
            cdef cbranch.Branch* br = cbus.BUS_get_reg_tran(self._c_bus)
            while br is not NULL:
                reg_trans.append(new_Branch(br))
                br = cbranch.BRANCH_get_reg_next(br)
            return reg_trans

    property reg_shunts:
        """ List of :class:`switched shunt devices <pfnet.Shunt>` regulating the voltage magnitude of this bus (list). """
        def __get__(self):
            reg_shunts = []
            cdef cshunt.Shunt* s = cbus.BUS_get_reg_shunt(self._c_bus)
            while s is not NULL:
                reg_shunts.append(new_Shunt(s))
                s = cshunt.SHUNT_get_reg_next(s)
            return reg_shunts

    property branches_from:
        """ List of :class:`branches <pfnet.Branch>` that have this bus on the "from" side (list). """
        def __get__(self):
            branches = []
            cdef cbranch.Branch* br = cbus.BUS_get_branch_from(self._c_bus)
            while br is not NULL:
                branches.append(new_Branch(br))
                br = cbranch.BRANCH_get_from_next(br)
            return branches

    property branches_to:
        """ List of :class:`branches <pfnet.Branch>` that have this bus on the "to" side (list). """
        def __get__(self):
            branches = []
            cdef cbranch.Branch* br = cbus.BUS_get_branch_to(self._c_bus)
            while br is not NULL:
                branches.append(new_Branch(br))
                br = cbranch.BRANCH_get_to_next(br)
            return branches

    property branches:
        """ List of :class:`branches <pfnet.Branch>` incident on this bus (list). """
        def __get__(self):
            return self.branches_from+self.branches_to

    property loads:
        """ List of :class:`loads <pfnet.Load>` connected to this bus (list). """
        def __get__(self):
            loads = []
            cdef cload.Load* l = cbus.BUS_get_load(self._c_bus)
            while l is not NULL:
                loads.append(new_Load(l))
                l = cload.LOAD_get_next(l)
            return loads

cdef new_Bus(cbus.Bus* b):
    if b is not NULL:
        bus = Bus(alloc=False)
        bus._c_bus = b
        return bus
    else:
        raise BusError('no bus data')

# Branch
########

# Properties
BRANCH_PROP_ANY = cbranch.BRANCH_PROP_ANY
BRANCH_PROP_TAP_CHANGER = cbranch.BRANCH_PROP_TAP_CHANGER
BRANCH_PROP_TAP_CHANGER_V = cbranch.BRANCH_PROP_TAP_CHANGER_V
BRANCH_PROP_TAP_CHANGER_Q = cbranch.BRANCH_PROP_TAP_CHANGER_Q
BRANCH_PROP_PHASE_SHIFTER = cbranch.BRANCH_PROP_PHASE_SHIFTER

# Variables
BRANCH_VAR_RATIO = cbranch.BRANCH_VAR_RATIO
BRANCH_VAR_RATIO_DEV = cbranch.BRANCH_VAR_RATIO_DEV
BRANCH_VAR_PHASE = cbranch.BRANCH_VAR_PHASE

class BranchError(Exception):
    """
    Branch error exception.
    """
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Branch:
    """
    Branch class.
    """

    cdef cbranch.Branch* _c_branch

    def __init__(self,alloc=True):
        """
        Branch class.

        Parameters
        ----------
        alloc : {``True``, ``False``}
        """

        pass

    def __cinit__(self,alloc=True):

        if alloc:
            self._c_branch = cbranch.BRANCH_new()
        else:
            self._c_branch = NULL

    def has_pos_ratio_v_sens(self):
        """
        Determines whether tap-changing transformer has positive
        sensitivity between tap ratio and controlled bus voltage magnitude.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_has_pos_ratio_v_sens(self._c_branch)

    def is_fixed_tran(self):
        """
        Determines whether branch is fixed transformer.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_is_fixed_tran(self._c_branch)

    def is_line(self):
        """
        Determines whether branch is transmission line.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_is_line(self._c_branch)

    def is_phase_shifter(self):
        """
        Determines whether branch is phase shifter.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_is_phase_shifter(self._c_branch)

    def is_tap_changer(self):
        """
        Determines whether branch is tap-changing transformer.

        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        return cbranch.BRANCH_is_tap_changer(self._c_branch)

    def is_tap_changer_v(self):
        """
        Determines whether branch is tap-changing transformer
        that regulates bus voltage magnitude.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_is_tap_changer_v(self._c_branch)

    def is_tap_changer_Q(self):
        """
        Determines whether branch is tap-changing transformer
        that regulates reactive power flow.

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_is_tap_changer_Q(self._c_branch)

    def has_flags(self,fmask,vmask):
        """
        Determines whether the branch has the flags associated with
        specific quantities set.

        Parameters
        ----------
        fmask : int (:ref:`ref_net_flag`)
        vmask : int (:ref:`ref_branch_var`)

        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cbranch.BRANCH_has_flags(self._c_branch,fmask,vmask)

    property index:
        """ Branch index (int). """
        def __get__(self): return cbranch.BRANCH_get_index(self._c_branch)

    property index_ratio:
        """ Index of transformer tap ratio variable (int). """
        def __get__(self): return cbranch.BRANCH_get_index_ratio(self._c_branch)

    property index_ratio_y:
        """ Index of transformer tap ratio positive deviation variable (int). """
        def __get__(self): return cbranch.BRANCH_get_index_ratio_y(self._c_branch)

    property index_ratio_z:
        """ Index of transformer tap ratio negative deviation variable (int). """
        def __get__(self): return cbranch.BRANCH_get_index_ratio_z(self._c_branch)

    property index_phase:
        """ Index of transformer phase shift variable (int). """
        def __get__(self): return cbranch.BRANCH_get_index_phase(self._c_branch)

    property ratio:
        """ Transformer tap ratio (float). """
        def __get__(self): return cbranch.BRANCH_get_ratio(self._c_branch)

    property ratio_max:
        """ Transformer tap ratio upper limit (float). """
        def __get__(self): return cbranch.BRANCH_get_ratio_max(self._c_branch)
        def __set__(self,value): cbranch.BRANCH_set_ratio_max(self._c_branch,value)

    property ratio_min:
        """ Transformer tap ratio lower limit (float). """
        def __get__(self): return cbranch.BRANCH_get_ratio_min(self._c_branch)
        def __set__(self,value): cbranch.BRANCH_set_ratio_min(self._c_branch,value)

    property bus_from:
        """ :class:`Bus <pfnet.Bus>` connected to the "from" side. """
        def __get__(self): return new_Bus(cbranch.BRANCH_get_bus_from(self._c_branch))
   
    property bus_to:
        """ :class:`Bus <pfnet.Bus>` connected to the "to" side. """
        def __get__(self): return new_Bus(cbranch.BRANCH_get_bus_to(self._c_branch))

    property reg_bus:
        """ :class:`Bus <pfnet.Bus>` whose voltage is regulated by this tap-changing transformer. """
        def __get__(self): return new_Bus(cbranch.BRANCH_get_reg_bus(self._c_branch))

    property b:
        """ Branch series susceptance (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_b(self._c_branch)

    property b_from:
        """ Branch shunt susceptance at the "from" side (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_b_from(self._c_branch)

    property b_to:
        """ Branch shunt susceptance at the "to" side (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_b_to(self._c_branch)

    property g:
        """ Branch series conductance (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_g(self._c_branch)

    property g_from:
        """ Branch shunt conductance at the "from" side (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_g_from(self._c_branch)

    property g_to:
        """ Branch shunt conductance at the "to" side (p.u.) (float). """
        def __get__(self): return cbranch.BRANCH_get_g_to(self._c_branch)

    property phase:
        """ Transformer phase shift (radians) (float). """
        def __get__(self): return cbranch.BRANCH_get_phase(self._c_branch)

    property phase_max:
        """ Transformer phase shift upper limit (radians) (float). """
        def __get__(self): return cbranch.BRANCH_get_phase_max(self._c_branch)

    property phase_min:
        """ Transformer phase shift lower limit (radians) (float). """
        def __get__(self): return cbranch.BRANCH_get_phase_min(self._c_branch)
   
cdef new_Branch(cbranch.Branch* b):
    if b is not NULL:
        branch = Branch(alloc=False)
        branch._c_branch = b
        return branch
    else:
        raise BranchError('no branch data')

# Generator
###########

# Properties
GEN_PROP_ANY = cgen.GEN_PROP_ANY
GEN_PROP_SLACK = cgen.GEN_PROP_SLACK
GEN_PROP_REG = cgen.GEN_PROP_REG
GEN_PROP_NOT_REG = cgen.GEN_PROP_NOT_REG
GEN_PROP_NOT_SLACK = cgen.GEN_PROP_NOT_SLACK

# Variables
GEN_VAR_P = cgen.GEN_VAR_P
GEN_VAR_Q = cgen.GEN_VAR_Q

class GeneratorError(Exception):
    """ 
    Generator error exception.
    """
    
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Generator:
    """
    Generator class.
    """

    cdef cgen.Gen* _c_gen

    def __init__(self,alloc=True):
        """
        Generator class.

        Parameters
        ----------
        alloc : {``True``, ``False``}
        """

        pass

    def __cinit__(self,alloc=True):

        if alloc:
            self._c_gen = cgen.GEN_new()
        else:
            self._c_gen = NULL

    def is_slack(self):
        """ 
        Determines whether generator is slack.
        
        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cgen.GEN_is_slack(self._c_gen)

    def is_regulator(self):
        """ 
        Determines whether generator provides voltage regulation.
        
        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        return cgen.GEN_is_regulator(self._c_gen)

    def has_flags(self,fmask,vmask):
        """ 
        Determines whether the generator has the flags associated with
        certain quantities set. 

        Parameters
        ----------
        fmask : int (:ref:`ref_net_flag`)
        vmask : int (:ref:`ref_gen_var`)
        
        Returns
        -------
        flag : {``True``, ``False``}
        """

        return cgen.GEN_has_flags(self._c_gen,fmask,vmask)

    property index:
        """ Generator index (int). """
        def __get__(self): return cgen.GEN_get_index(self._c_gen)
        
    property index_P:
        """ Index of generator active power variable (int). """
        def __get__(self): return cgen.GEN_get_index_P(self._c_gen)

    property index_Q:
        """ Index of generator reactive power variable (int). """
        def __get__(self): return cgen.GEN_get_index_Q(self._c_gen)

    property bus:
        """ :class:`Bus <pfnet.Bus>` to which generator is connected. """
        def __get__(self): return new_Bus(cgen.GEN_get_bus(self._c_gen))

    property reg_bus:
        """ :class:`Bus <pfnet.Bus>` whose voltage is regulated by this generator. """
        def __get__(self): return new_Bus(cgen.GEN_get_reg_bus(self._c_gen))

    property P:
        """ Generator active power (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_P(self._c_gen)

    property P_max:
        """ Generator active power upper limit (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_P_max(self._c_gen)

    property P_min:
        """ Generator active power lower limit (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_P_min(self._c_gen)
            
    property Q:
        """ Generator reactive power (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_Q(self._c_gen)

    property Q_max:
        """ Generator reactive power upper limit (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_Q_max(self._c_gen)

    property Q_min:
        """ Generator reactive power lower limit (p.u. system base MVA) (float). """
        def __get__(self): return cgen.GEN_get_Q_min(self._c_gen)

    property cost_coeff_Q0:
        """ Coefficient for quadratic genertion cost (constant term). """
        def __get__(self): return cgen.GEN_get_cost_coeff_Q0(self._c_gen)

    property cost_coeff_Q1:
        """ Coefficient for quadratic genertion cost (linear term). """
        def __get__(self): return cgen.GEN_get_cost_coeff_Q1(self._c_gen)

    property cost_coeff_Q2:
        """ Coefficient for quadratic genertion cost (quadratic term). """
        def __get__(self): return cgen.GEN_get_cost_coeff_Q2(self._c_gen)

cdef new_Generator(cgen.Gen* g):
    if g is not NULL:
        gen = Generator(alloc=False)
        gen._c_gen = g
        return gen
    else:
        raise GeneratorError('no gen data')

# Shunt
#######

# Properties
SHUNT_PROP_ANY = cshunt.SHUNT_PROP_ANY
SHUNT_PROP_SWITCHED_V = cshunt.SHUNT_PROP_SWITCHED_V

# Variables
SHUNT_VAR_SUSC = cshunt.SHUNT_VAR_SUSC
SHUNT_VAR_SUSC_DEV = cshunt.SHUNT_VAR_SUSC_DEV

class ShuntError(Exception):
    """
    Shunt error exception.
    """
    
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Shunt:
    """
    Shunt class.
    """

    cdef cshunt.Shunt* _c_shunt

    def __init__(self,alloc=True):
        """
        Shunt class.

        Parameters
        ----------
        alloc : {``True``, ``False``}
        """

        pass

    def __cinit__(self,alloc=True):

        if alloc:
            self._c_shunt = cshunt.SHUNT_new()
        else:
            self._c_shunt = NULL

    def is_fixed(self):
        """
        Determines whether the shunt device is fixed (as opposed to switched).

        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        return cshunt.SHUNT_is_fixed(self._c_shunt)

    def is_switched_v(self):
        """
        Determines whether the shunt is switchable and regulates 
        bus voltage magnitude.

        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        return cshunt.SHUNT_is_switched_v(self._c_shunt)

    def has_flags(self,fmask,vmask):
        """
        Determines whether the shunt devices has flags associated with 
        certain quantities set.
        
        Parameters
        ----------
        fmask : int (:ref:`ref_net_flag`)
        vmask : int (:ref:`ref_bus_var`)

        Returns
        -------
        flag : {``True``, ``False``}
        """
        
        return cshunt.SHUNT_has_flags(self._c_shunt,fmask,vmask)

    property index:
        """ Shunt index (int). """
        def __get__(self): return cshunt.SHUNT_get_index(self._c_shunt)    

    property index_b:
        """ Index of shunt susceptance variable (int). """
        def __get__(self): return cshunt.SHUNT_get_index_b(self._c_shunt)

    property index_y:
        """ Index of shunt susceptance positive deviation variable (int). """
        def __get__(self): return cshunt.SHUNT_get_index_y(self._c_shunt)

    property index_z:
        """ Index of shunt susceptance negative deviation variable (int). """
        def __get__(self): return cshunt.SHUNT_get_index_z(self._c_shunt)

    property bus:
        """ :class:`Bus <pfnet.Bus>` to which the shunt devices is connected. """
        def __get__(self): return new_Bus(cshunt.SHUNT_get_bus(self._c_shunt))

    property reg_bus:
        """ :class:`Bus <pfnet.Bus>` whose voltage magnitude is regulated by this shunt device. """
        def __get__(self): return new_Bus(cshunt.SHUNT_get_reg_bus(self._c_shunt))

    property g:
        """ Shunt conductance (p.u.) (float). """
        def __get__(self): return cshunt.SHUNT_get_g(self._c_shunt)
            
    property b:
        """ Shunt susceptance (p.u.) (float). """
        def __get__(self): return cshunt.SHUNT_get_b(self._c_shunt)

    property b_max:
        """ Shunt susceptance upper limit (p.u.) (float). """
        def __get__(self): return cshunt.SHUNT_get_b_max(self._c_shunt)
        def __set__(self,value): cshunt.SHUNT_set_b_max(self._c_shunt,value)

    property b_min:
        """ Shunt susceptance lower limit (p.u.) (float). """
        def __get__(self): return cshunt.SHUNT_get_b_min(self._c_shunt)
        def __set__(self,value): cshunt.SHUNT_set_b_min(self._c_shunt,value)                

cdef new_Shunt(cshunt.Shunt* s):
    if s is not NULL:
        shunt = Shunt(alloc=False)
        shunt._c_shunt = s
        return shunt
    else:
        raise ShuntError('no shunt data')

# Load
######

class LoadError(Exception):
    """ 
    Load error exception.
    """
    
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Load:
    """
    Load class.
    """

    cdef cload.Load* _c_load

    def __init__(self,alloc=True):
        """
        Load class.

        Parameters
        ----------
        alloc : {``True``, ``False``}
        """

        pass

    def __cinit__(self,alloc=True):

        if alloc:
            self._c_load = cload.LOAD_new()
        else:
            self._c_load = NULL

    property index:
        """ Load index (int). """
        def __get__(self): return cload.LOAD_get_index(self._c_load)
        
    property bus:
        """ :class:`Bus <pfnet.Bus>` to which load is connected. """
        def __get__(self): return new_Bus(cload.LOAD_get_bus(self._c_load))

    property P:
        """ Load active power (p.u. system base MVA) (float). """
        def __get__(self): return cload.LOAD_get_P(self._c_load)
        def __set__(self,value): cload.LOAD_set_P(self._c_load,value)
            
    property Q:
        """ Load reactive power (p.u. system base MVA) (float). """
        def __get__(self): return cload.LOAD_get_Q(self._c_load)
        def __set__(self,value): cload.LOAD_set_Q(self._c_load,value)

cdef new_Load(cload.Load* l):
    if l is not NULL:
        load = Load(alloc=False)
        load._c_load = l
        return load
    else:
        raise LoadError('no load data')

# Network
#########

class NetworkError(Exception):
    """
    Network error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Network:
    """
    Network class.
    """

    cdef cnet.Net* _c_net
    cdef bint alloc

    def __init__(self,alloc=True):
        """
        Network class.

        Parameters
        ----------
        alloc : {``True``, ``False``}
        """

        pass
     
    def __cinit__(self,alloc=True):

        if alloc:
            self._c_net = cnet.NET_new()
        else:
            self._c_net = NULL
        self.alloc = alloc

    def adjust_generators(self):
        """
        Adjusts powers of slack and regulator generators connected to or regulating the
        same bus to correct generator participations without modifying the total power injected.
        """
        
        cnet.NET_adjust_generators(self._c_net);

    def clear_flags(self):
        """
        Clears all the flags of all the network components.
        """

        cnet.NET_clear_flags(self._c_net)

    def clear_properties(self):
        """
        Clears all the network properties.
        """

        cnet.NET_clear_properties(self._c_net)

    def clear_sensitivities(self):
        """
        Clears all sensitivity information.
        """
        
        cnet.NET_clear_sensitivities(self._c_net)

    def create_sorted_bus_list(self,sort_by):
        """
        Creates list of buses sorted in descending order according to a specific quantity.

        Parameters
        ----------
        sort_by : int (:ref:`ref_bus_sens`, :ref:`ref_bus_mis`).

        Returns
        -------
        buses : list of :class:`Buses <pfnet.Bus>`
        """

        buses = []
        cdef cbus.Bus* b = cnet.NET_create_sorted_bus_list(self._c_net,sort_by)
        while b is not NULL:
            buses.append(new_Bus(b))
            b = cbus.BUS_get_next(b)
        return buses
        
    def get_bus_by_number(self,number):
        """
        Gets bus with the given number.

        Parameters
        ----------
        number : int
        
        Returns
        -------
        bus : :class:`Bus <pfnet.Bus>`
        """

        ptr = cnet.NET_bus_hash_find(self._c_net,number)
        if ptr is not NULL:
            return new_Bus(ptr)
        else:
            raise NetworkError('bus not found')

    def __dealloc__(self):
        """
        Frees network C data structure. 
        """
        
        if self.alloc:
            cnet.NET_del(self._c_net)
            self._c_net = NULL
            
    def get_bus(self,index):
        """
        Gets bus with the given index.

        Parameters
        ----------
        index : int

        Returns
        -------
        bus : :class:`Bus <pfnet.Bus>`
        """

        ptr = cnet.NET_get_bus(self._c_net,index)
        if ptr is not NULL:
            return new_Bus(ptr)
        else:
            raise NetworkError('invalid bus index')

    def get_branch(self,index):
        """
        Gets branch with the given index.

        Parameters
        ----------
        index : int

        Returns
        -------
        branch : :class:`Branch <pfnet.Branch>`
        """
        
        ptr = cnet.NET_get_branch(self._c_net,index)
        if ptr is not NULL:
            return new_Branch(ptr)
        else:
            raise NetworkError('invalid ranch index')

    def get_gen(self,index):
        """
        Gets generator with the given index.

        Parameters
        ----------
        index : int

        Returns
        -------
        gen : :class:`Generator <pfnet.Generator>`
        """

        ptr = cnet.NET_get_gen(self._c_net,index)
        if ptr is not NULL:
            return new_Generator(ptr)
        else:
            raise NetworkError('invalid gen index')

    def get_shunt(self,index):
        """
        Gets shunt with the given index.

        Parameters
        ----------
        index : int

        Returns
        -------
        gen : :class:`Shunt <pfnet.Shunt>`
        """

        ptr = cnet.NET_get_shunt(self._c_net,index)
        if ptr is not NULL:
            return new_Shunt(ptr)
        else:
            raise NetworkError('invalid shunt index')

    def get_load(self,index):
        """
        Gets load with the given index.

        Parameters
        ----------
        index : int

        Returns
        -------
        gen : :class:`Load <pfnet.Load>`
        """

        ptr = cnet.NET_get_load(self._c_net,index)
        if ptr is not NULL:
            return new_Load(ptr)
        else:
            raise NetworkError('invalid load index')

    def get_var_values(self):
        """
        Gets network variable values.

        Returns
        -------
        values : :class:`ndarray <numpy.ndarray>`
        """
        return Vector(cnet.NET_get_var_values(self._c_net))

    def get_num_buses(self):
        """
        Gets number of buses in the network.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_buses(self._c_net)

    def get_num_slack_buses(self):
        """
        Gets number of slack buses in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_slack_buses(self._c_net)

    def get_num_buses_reg_by_gen(self):
        """
        Gets number of buses whose voltage magnitudes are regulated by generators.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_buses_reg_by_gen(self._c_net)

    def get_num_buses_reg_by_tran(self,only=False):
        """
        Gets number of buses whose voltage magnitudes are regulated by tap-changing transformers.

        Returns
        -------
        num : int
        """

        if not only:
            return cnet.NET_get_num_buses_reg_by_tran(self._c_net)
        else:
            return cnet.NET_get_num_buses_reg_by_tran_only(self._c_net)

    def get_num_buses_reg_by_shunt(self,only=False):
        """
        Gets number of buses whose voltage magnitudes are regulated by switched shunt devices.

        Returns
        -------
        num : int
        """
        
        if not only:
            return cnet.NET_get_num_buses_reg_by_shunt(self._c_net)
        else:
            return cnet.NET_get_num_buses_reg_by_shunt_only(self._c_net)

    def get_num_branches(self):
        """
        Gets number of branches in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_branches(self._c_net)

    def get_num_fixed_trans(self):
        """
        Gets number of fixed transformers in the network.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_fixed_trans(self._c_net)

    def get_num_lines(self):
        """
        Gets number of transmission lines in the network.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_lines(self._c_net)

    def get_num_phase_shifters(self):
        """
        Gets number of phase-shifting transformers in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_phase_shifters(self._c_net)

    def get_num_tap_changers(self):
        """
        Gets number of tap-changing transformers in the network.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_tap_changers(self._c_net)

    def get_num_tap_changers_v(self):
        """
        Gets number of tap-changing transformers in the network that regulate voltage magnitudes.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_tap_changers_v(self._c_net)

    def get_num_tap_changers_Q(self):
        """
        Gets number of tap-changing transformers in the network that regulate reactive flows.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_tap_changers_Q(self._c_net)

    def get_num_gens(self):
        """
        Gets number of generators in the network.

        Returns
        -------
        num : int
        """
        
        return cnet.NET_get_num_gens(self._c_net)

    def get_num_reg_gens(self):
        """
        Gets number generators in the network that provide voltage regulation.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_reg_gens(self._c_net)

    def get_num_slack_gens(self):
        """
        Gets number of slack generators in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_slack_gens(self._c_net)

    def get_num_loads(self):
        """
        Gets number of loads in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_loads(self._c_net)

    def get_num_shunts(self):
        """
        Gets number of shunts in the network.
        
        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_shunts(self._c_net)

    def get_num_fixed_shunts(self):
        """
        Gets number of fixed shunts in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_fixed_shunts(self._c_net)

    def get_num_switched_shunts(self):
        """
        Gets number of switched shunts in the network.

        Returns
        -------
        num : int
        """

        return cnet.NET_get_num_switched_shunts(self._c_net)

    def get_properties(self):
        """
        Gets network properties.

        Returns
        -------
        properties : dict
        """

        return {'bus_v_max': self.bus_v_max,
                'bus_v_min': self.bus_v_min,
                'bus_v_vio': self.bus_v_vio,
                'bus_P_mis': self.bus_P_mis,
                'bus_Q_mis': self.bus_Q_mis,
                'gen_v_dev': self.gen_v_dev,
                'gen_Q_vio': self.gen_Q_vio,
                'gen_P_vio': self.gen_P_vio,
                'tran_v_vio': self.tran_v_vio,
                'tran_r_vio': self.tran_r_vio,
                'tran_p_vio': self.tran_p_vio,
                'shunt_v_vio': self.shunt_v_vio,
                'shunt_b_vio': self.shunt_b_vio,
                'num_actions': self.num_actions}

    def load(self,filename):
        """
        Loads a network data contained in a specific file.
        
        Parameters
        ----------
        filename : string        
        """

        cnet.NET_load(self._c_net,filename)
        if cnet.NET_has_error(self._c_net):
            raise NetworkError(cnet.NET_get_error_string(self._c_net))

    def set_flags(self,obj_type,flags,props,vals):
        """
        Sets flags of network components with specific properties.

        Parameters
        ----------
        obj_type : int (:ref:`ref_net_obj`)
        flags : int or list (:ref:`ref_net_flag`)
        props : int or list (:ref:`ref_bus_prop`, :ref:`ref_branch_prop`, :ref:`ref_gen_prop`, :ref:`ref_shunt_prop`)
        vals : int or list (:ref:`ref_bus_var`, :ref:`ref_branch_var`, :ref:`ref_gen_var`, :ref:`ref_shunt_var`)
        """

        props = props if isinstance(props,list) else [props]
        vals = vals if isinstance(vals,list) else [vals]
        flags = flags if isinstance(flags,list) else [flags]
        cnet.NET_set_flags(self._c_net,
                           obj_type,
                           reduce(lambda x,y: x|y,flags,0),
                           reduce(lambda x,y: x|y,props,0),
                           reduce(lambda x,y: x|y,vals,0))
        if cnet.NET_has_error(self._c_net):
            raise NetworkError(cnet.NET_get_error_string(self._c_net))

    def set_var_values(self,values):
        """
        Sets network variable values.

        Parameters
        ----------
        values : :class:`ndarray <numpy.ndarray>`
        """

        cdef np.ndarray[double,mode='c'] x = values
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if values.size else NULL
        cnet.NET_set_var_values(self._c_net,v)

    def show_components(self):
        """
        Shows information about the number of network components of each type.
        """
        
        cnet.NET_show_components(self._c_net)
	 	 
    def show_properties(self):
        """
        Shows information about the state of the network component quantities.
        """

        cnet.NET_show_properties(self._c_net)

    def show_buses(self,number,sort_by):
        """
        Shows information about the most relevant network buses sorted by a specific quantity.

        Parameters
        ----------
        number : int
        sort_by : int (:ref:`ref_bus_sens`, :ref:`ref_bus_mis`)
        """
        
        cnet.NET_show_buses(self._c_net,number,sort_by)

    def update_properties(self,values=None):
        """
        Re-computes the network properties using the given values
        of the network variables. If no values are given, then the
        current values of the network variables are used.

        Parameters
        ----------
        values : :class:`ndarray <numpy.ndarray>`
        """
            
        cdef cvec.Vec* v = NULL
        cdef np.ndarray[double,mode='c'] x = values
        if values is not None:
            v = cvec.VEC_new_from_array(&(x[0]),len(x)) if x.size else NULL
        else:
            v = NULL
        cnet.NET_update_properties(self._c_net,v)

    def update_set_points(self):
        """
        Updates voltage magnitude set points of gen-regulated buses 
        to be equal to the bus voltage magnitudes.
        """

        cnet.NET_update_set_points(self._c_net)

    property base_power:
        """ System base power (MVA) (float). """
        def __get__(self): return cnet.NET_get_base_power(self._c_net)

    property buses:
        """ List of network :class:`buses <pfnet.Bus>` (list). """
        def __get__(self):
            return [self.get_bus(i) for i in range(self.num_buses)]

    property branches:
        """ List of network :class:`branches <pfnet.Branch>` (list). """
        def __get__(self):
            return [self.get_branch(i) for i in range(self.num_branches)]

    property generators:
        """ List of network :class:`generators <pfnet.Generator>` (list). """
        def __get__(self):
            return [self.get_gen(i) for i in range(self.num_gens)]

    property shunts:
        """ List of network :class:`shunts <pfnet.Shunt>` (list). """
        def __get__(self):
            return [self.get_shunt(i) for i in range(self.num_shunts)]

    property loads:
        """ List of network :class:`loads <pfnet.Load>` (list). """
        def __get__(self):
            return [self.get_load(i) for i in range(self.num_loads)]
    
    property num_buses:
        """ Number of buses in the network (int). """
        def __get__(self): return cnet.NET_get_num_buses(self._c_net)

    property num_branches:
        """ Number of branches in the network (int). """
        def __get__(self): return cnet.NET_get_num_branches(self._c_net)

    property num_gens:
        """ Number of generators in the network (int). """
        def __get__(self): return cnet.NET_get_num_gens(self._c_net)

    property num_loads:
        """ Number of loads in the network (int). """
        def __get__(self): return cnet.NET_get_num_loads(self._c_net)

    property num_shunts:
        """ Number of shunt devices in the network (int). """
        def __get__(self): return cnet.NET_get_num_shunts(self._c_net)

    property num_vars:
        """ Number of network quantities that have been set to variable (int). """
        def __get__(self): return cnet.NET_get_num_vars(self._c_net)

    property num_fixed:
        """ Number of network quantities that have been set to fixed (int). """
        def __get__(self): return cnet.NET_get_num_fixed(self._c_net)

    property num_bounded:
        """ Number of network quantities that have been set to bounded (int). """
        def __get__(self): return cnet.NET_get_num_bounded(self._c_net)

    property num_sparse:
        """ Number of network control quantities that have been set to sparse (int). """
        def __get__(self): return cnet.NET_get_num_sparse(self._c_net)

    property bus_v_max:
        """ Maximum bus voltage magnitude (p.u.) (float). """
        def __get__(self): return cnet.NET_get_bus_v_max(self._c_net)

    property bus_v_min:
        """ Minimum bus voltage magnitude (p.u.) (float). """
        def __get__(self): return cnet.NET_get_bus_v_min(self._c_net)

    property bus_v_vio:
        """ Maximum bus voltage magnitude limit violation (p.u.) (float). """
        def __get__(self): return cnet.NET_get_bus_v_vio(self._c_net)

    property bus_P_mis:
        """ Largest bus active power mismatch in the network (MW) (float). """
        def __get__(self): return cnet.NET_get_bus_P_mis(self._c_net)

    property bus_Q_mis:
        """ Largest bus reactive power mismatch in the network (MVAr) (float). """
        def __get__(self): return cnet.NET_get_bus_Q_mis(self._c_net)

    property gen_v_dev:
        """ Largest voltage magnitude deviation from set point of bus regulated by generator (p.u.) (float). """
        def __get__(self): return cnet.NET_get_gen_v_dev(self._c_net)

    property gen_Q_vio:
        """ Largest generator reactive power limit violation (MVAr) (float). """
        def __get__(self): return cnet.NET_get_gen_Q_vio(self._c_net)

    property gen_P_vio:
        """ Largest generator active power limit violation (MW) (float). """
        def __get__(self): return cnet.NET_get_gen_P_vio(self._c_net)

    property tran_v_vio:
        """ Largest voltage magnitude band violation of voltage regulated by transformer (p.u.) (float). """
        def __get__(self): return cnet.NET_get_tran_v_vio(self._c_net)

    property tran_r_vio:
        """ Largest transformer tap ratio limit violation (float). """
        def __get__(self): return cnet.NET_get_tran_r_vio(self._c_net)

    property tran_p_vio:
        """ Largest transformer phase shift limit violation (float). """
        def __get__(self): return cnet.NET_get_tran_p_vio(self._c_net)

    property shunt_v_vio:
        """ Largest voltage magnitude band violation of voltage regulated by switched shunt device (p.u.) (float). """
        def __get__(self): return cnet.NET_get_shunt_v_vio(self._c_net)

    property shunt_b_vio:
        """ Largest switched shunt susceptance limit violation (p.u.) (float). """
        def __get__(self): return cnet.NET_get_shunt_b_vio(self._c_net)

    property num_actions:
        """ Number of control adjustments (int). """
        def __get__(self): return cnet.NET_get_num_actions(self._c_net)

cdef new_Network(cnet.Net* n):
    if n is not NULL:
        net = Network(alloc=False)
        net._c_net = n
        return net
    else:
        raise NetworkError('no network data')

# Graph
#######

class GraphError(Exception):
    """
    Graph error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Graph:
    """
    Graph class.
    """

    cdef cgraph.Graph* _c_graph
    cdef cnet.Net* _c_net
    cdef bint alloc
    
    def __init__(self,net,alloc=True):
        """
        Graph class.
        
        Parameters
        ----------
        net : :class:`Network <pfnet.Network>`
        alloc : {``True``, ``False``}
        """

        pass
     
    def __cinit__(self,Network net, alloc=True):
        
        self._c_net = net._c_net
        if alloc:
            self._c_graph = cgraph.GRAPH_new(net._c_net)
        else:
            self._c_graph = NULL
        self.alloc = alloc

    def __dealloc__(self):
        """
        Frees graph C data structure. 
        """
        
        if self.alloc:
            cgraph.GRAPH_del(self._c_graph)
            self._c_graph = NULL
        
    def set_layout(self):
        """
        Determines and saves a layout for the graph nodes. 
        """

        cgraph.GRAPH_set_layout(self._c_graph)

    def set_nodes_property(self,prop,value):
        """
        Sets property of nodes. See `Graphviz documentation <http://www.graphviz.org/Documentation.php>`_.

        Parameters
        ----------
        prop : string
        value : string
        """
        
        cgraph.GRAPH_set_nodes_property(self._c_graph,prop,value)
        if cgraph.GRAPH_has_error(self._c_graph):
            raise GraphError(cgraph.GRAPH_get_error_string(self._c_graph))

    def set_edges_property(self,prop,value):
        """
        Sets property of edges. See `Graphviz documentation <http://www.graphviz.org/Documentation.php>`_.

        Parameters
        ----------
        prop : string
        value : string
        """
        
        cgraph.GRAPH_set_edges_property(self._c_graph,prop,value)
        if cgraph.GRAPH_has_error(self._c_graph):
            raise GraphError(cgraph.GRAPH_get_error_string(self._c_graph))

    def color_nodes_by_mismatch(self,mis_type):
        """
        Colors the graphs nodes according to their power mismatch.
        
        Parameters
        ----------
        mis_type : int (:ref:`ref_bus_mis`)
        """
        
        cgraph.GRAPH_color_nodes_by_mismatch(self._c_graph,mis_type)
        if cgraph.GRAPH_has_error(self._c_graph):
            raise GraphError(cgraph.GRAPH_get_error_string(self._c_graph))

    def color_nodes_by_sensitivity(self,sens_type):
        """
        Colors the graphs nodes according to their sensitivity.

        Parameters
        ----------
        sens_type : int (:ref:`ref_bus_sens`)
        """

        cgraph.GRAPH_color_nodes_by_sensitivity(self._c_graph,sens_type)
        if cgraph.GRAPH_has_error(self._c_graph):
            raise GraphError(cgraph.GRAPH_get_error_string(self._c_graph))

    def view(self):
        """
        Displays the graph.
        """

        temp = tempfile.NamedTemporaryFile(delete=True)
        try:
            self.write("png",temp.name)
            im = misc.imread(temp.name)
            misc.imshow(im)
        finally:
            temp.close()
            
    def write(self,format,filename):
        """
        Writes the graph to a file.

        Parameters
        ----------
        format : string (`Graphviz output formats <http://www.graphviz.org/content/output-formats>`_)
        filename : string
        """

        cgraph.GRAPH_write(self._c_graph,format,filename)
        if cgraph.GRAPH_has_error(self._c_graph):
            raise GraphError(cgraph.GRAPH_get_error_string(self._c_graph))

# Function
##########

# Types
FUNC_TYPE_REG_VMAG = cfunc.FUNC_TYPE_REG_VMAG
FUNC_TYPE_REG_VANG = cfunc.FUNC_TYPE_REG_VANG
FUNC_TYPE_REG_PQ = cfunc.FUNC_TYPE_REG_PQ
FUNC_TYPE_REG_RATIO = cfunc.FUNC_TYPE_REG_RATIO
FUNC_TYPE_REG_PHASE = cfunc.FUNC_TYPE_REG_PHASE
FUNC_TYPE_REG_SUSC = cfunc.FUNC_TYPE_REG_SUSC
FUNC_TYPE_GEN_COST = cfunc.FUNC_TYPE_GEN_COST
FUNC_TYPE_SP_CONTROLS = cfunc.FUNC_TYPE_SP_CONTROLS
FUNC_TYPE_SLIM_VMAG = cfunc.FUNC_TYPE_SLIM_VMAG

class FunctionError(Exception):
    """
    Function error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Function:
    """
    Function class.
    """

    cdef cfunc.Func* _c_func
    cdef bint alloc

    def __init__(self, int type, float weight, Network net, alloc=True):
        """
        Function class.
        
        Parameters
        ----------
        type : int (:ref:`ref_func_type`)
        weight : float
        net : :class:`Network <pfnet.Network>`
        alloc : {``True``, ``False``}
        """

        pass
     
    def __cinit__(self, int type, float weight, Network net, alloc=True):
        
        if alloc:
            self._c_func = cfunc.FUNC_new(type,weight,net._c_net)
        else:
            self._c_func = NULL
        self.alloc = alloc

    def __dealloc__(self):
        """
        Frees function C data structure. 
        """
        
        if self.alloc:
            cfunc.FUNC_del(self._c_func)
            self._c_func = NULL
            
    def update_network(self):
        """
        Updates internal arrays to be compatible
        with any network changes.
        """

        cfunc.FUNC_update_network(self._c_func)

    def clear_error(self):
        """
        Clears internal error flag.
        """

        cfunc.FUNC_clear_error(self._c_func)
        
    def analyze(self):
        """
        Analyzes function and allocates required vectors and matrices.
        """

        cfunc.FUNC_count(self._c_func)
        cfunc.FUNC_allocate(self._c_func)
        cfunc.FUNC_analyze(self._c_func)
        if cfunc.FUNC_has_error(self._c_func):
            raise FunctionError(cfunc.FUNC_get_error_string(self._c_func))
        
    def eval(self,var_values):
        """
        Evaluates function value, gradient, and Hessian using 
        the given variable values. 
        
        Parameters
        ----------
        var_values : :class:`ndarray <numpy.ndarray>`
        """

        cdef np.ndarray[double,mode='c'] x = var_values
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if var_values.size else NULL
        cfunc.FUNC_eval(self._c_func,v)
        if cfunc.FUNC_has_error(self._c_func):
            raise FunctionError(cfunc.FUNC_get_error_string(self._c_func))

    property type:
        """ Function type (int). """
        def __get__(self): return cfunc.FUNC_get_type(self._c_func)

    property Hcounter:
        """ Number of nonzero entries in Hessian matrix (int). """
        def __get__(self): return cfunc.FUNC_get_Hcounter(self._c_func)
        
    property phi:
        """ Function value (float). """
        def __get__(self): return cfunc.FUNC_get_phi(self._c_func)

    property gphi:
        """ Function gradient vector (:class:`ndarray <numpy.ndarray>`). """   
        def __get__(self): return Vector(cfunc.FUNC_get_gphi(self._c_func))

    property Hphi:
        """ Function Hessian matrix (only the lower triangular part) (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cfunc.FUNC_get_Hphi(self._c_func))

    property weight:
        """ Function weight (float). """
        def __get__(self): return cfunc.FUNC_get_weight(self._c_func)
        
cdef new_Function(cfunc.Func* f, cnet.Net* n):
    if f is not NULL and n is not NULL:
        func = Function(0,0,new_Network(n),alloc=False)
        func._c_func = f
        return func
    else:
        raise FunctionError('invalid function data')
    
# Constraint
############

# Types
CONSTR_TYPE_PF = cconstr.CONSTR_TYPE_PF
CONSTR_TYPE_FIX = cconstr.CONSTR_TYPE_FIX
CONSTR_TYPE_BOUND = cconstr.CONSTR_TYPE_BOUND
CONSTR_TYPE_PAR_GEN = cconstr.CONSTR_TYPE_PAR_GEN
CONSTR_TYPE_REG_GEN = cconstr.CONSTR_TYPE_REG_GEN
CONSTR_TYPE_REG_TRAN = cconstr.CONSTR_TYPE_REG_TRAN
CONSTR_TYPE_REG_SHUNT = cconstr.CONSTR_TYPE_REG_SHUNT

class ConstraintError(Exception):
    """
    Constraint error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Constraint:
    """
    Constraint class.
    """
    
    cdef cconstr.Constr* _c_constr
    cdef cnet.Net* _c_net
    cdef bint alloc

    def __init__(self,int type, Network net, alloc=True):
        """
        Constraint class.

        Parameters
        ----------
        type : int (:ref:`ref_constr_type`)
        net : :class:`Network <pfnet.Network>`
        alloc : {``True``, ``False``}
        """

        pass
     
    def __cinit__(self,int type, Network net, alloc=True):

        self._c_net = net._c_net
        if alloc:
            self._c_constr = cconstr.CONSTR_new(type,net._c_net)
        else:
            self._c_constr = NULL
        self.alloc = alloc
            
    def __dealloc__(self):
        """
        Frees constraint C data structure. 
        """
        
        if self.alloc:
            cconstr.CONSTR_del(self._c_constr)
            self._c_constr = NULL

    def update_network(self):
        """
        Updates internal arrays to be compatible
        with any network changes.
        """
        
        cconstr.CONSTR_update_network(self._c_constr)

    def clear_error(self):
        """
        Clears internal error flag.
        """

        cconstr.CONSTR_clear_error(self._c_constr)
        
    def analyze(self):
        """
        Analyzes constraint and allocates required vectors and matrices.
        """
        
        cconstr.CONSTR_count(self._c_constr)
        cconstr.CONSTR_allocate(self._c_constr)     
        cconstr.CONSTR_analyze(self._c_constr)
        if cconstr.CONSTR_has_error(self._c_constr):
            raise ConstraintError(cconstr.CONSTR_get_error_string(self._c_constr))

    def combine_H(self,coeff,ensure_psd=False):
        """
        Forms and saves a linear combination of the individual constraint Hessians.

        Parameters
        ----------
        coeff : :class:`ndarray <numpy.ndarray>`
        ensure_psd : {``True``, ``False``}
        """
        
        cdef np.ndarray[double,mode='c'] x = coeff
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if coeff.size else NULL
        cconstr.CONSTR_combine_H(self._c_constr,v,ensure_psd)
        if cconstr.CONSTR_has_error(self._c_constr):
            raise ConstraintError(cconstr.CONSTR_get_error_string(self._c_constr))
        
    def eval(self,var_values):
        """
        Evaluates constraint violations, Jacobian, and individual Hessian matrices.
        
        Parameters
        ----------
        var_values : :class:`ndarray <numpy.ndarray>`
        """
        
        cdef np.ndarray[double,mode='c'] x = var_values
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if var_values.size else NULL
        cconstr.CONSTR_eval(self._c_constr,v)
        if cconstr.CONSTR_has_error(self._c_constr):
            raise ConstraintError(cconstr.CONSTR_get_error_string(self._c_constr))

    def store_sensitivities(self,sens):
        """
        Stores Lagrange multiplier estimates of the nonlinear equality constraint in 
        the power network components.

        Parameters
        ----------
        sens : :class:`ndarray <numpy.ndarray>`
        """

        cdef np.ndarray[double,mode='c'] x = sens
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if sens.size else NULL
        cconstr.CONSTR_store_sens(self._c_constr,v)
        if cconstr.CONSTR_has_error(self._c_constr):
            raise ConstraintError(cconstr.CONSTR_get_error_string(self._c_constr))

    def get_H_single(self,i):
        """
        Gets the Hessian matrix (only lower triangular part) of an individual constraint.
        
        Parameters
        ----------
        i : int 
        
        Returns
        -------
        H : :class:`coo_matrix <scipy.sparse.coo_matrix>`
        """
        return Matrix(cconstr.CONSTR_get_H_single(self._c_constr,i))

    property type:
        """ Constraint type (:ref:`ref_constr_type`) (int). """
        def __get__(self): return cconstr.CONSTR_get_type(self._c_constr)

    property Acounter:
        """ Number of nonzero entries in the matrix of linear equality constraints (int). """
        def __get__(self): return cconstr.CONSTR_get_Acounter(self._c_constr)

    property Jcounter:
        """ Number of nonzero entries in the Jacobian matrix of the nonlinear equality constraints (int). """
        def __get__(self): return cconstr.CONSTR_get_Jcounter(self._c_constr)

    property Aconstr_index:
        """ Index of linear equality constraint (int). """
        def __get__(self): return cconstr.CONSTR_get_Aconstr_index(self._c_constr)

    property Jconstr_index:
        """ Index of nonlinear equality constraint (int). """
        def __get__(self): return cconstr.CONSTR_get_Jconstr_index(self._c_constr)
        
    property f:
        """ Vector of nonlinear equality constraint violations (:class:`ndarray <numpy.ndarray>`). """
        def __get__(self): return Vector(cconstr.CONSTR_get_f(self._c_constr))

    property J:
        """ Jacobian matrix of nonlinear equality constraints (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cconstr.CONSTR_get_J(self._c_constr))

    property b:
        """ Right-hand side vector of linear equality constraints (:class:`ndarray <numpy.ndarray>`). """
        def __get__(self): return Vector(cconstr.CONSTR_get_b(self._c_constr))
        
    property A:
        """ Matrix of linear equality constraints (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cconstr.CONSTR_get_A(self._c_constr))

    property H_combined:
        """ Linear combination of Hessian matrices of individual nonlinear equality constraints (only the lower triangular part) (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cconstr.CONSTR_get_H_combined(self._c_constr))

cdef new_Constraint(cconstr.Constr* c, cnet.Net* n):
    if c is not NULL and n is not NULL:
        constr = Constraint(0,new_Network(n),alloc=False)
        constr._c_constr = c
        return constr
    else:
        raise ConstraintError('invalid constraint data')

# Heuristic
###########

# Types
HEUR_TYPE_PVPQ = cheur.HEUR_TYPE_PVPQ

class HeuristicError(Exception):
    """
    Heuristic error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Heuristic:
    """
    Heuristic class.
    """

    pass

# Problem
#########        
    
class ProblemError(Exception):
    """
    Problem error exception.
    """

    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

cdef class Problem:
    """
    Optimization problem class.
    """
    
    cdef cprob.Prob* _c_prob
    cdef bint alloc

    def __init__(self):
        """
        Class constructor.
        """

        pass        

    def __cinit__(self):

        self._c_prob = cprob.PROB_new()
        self.alloc = True
        
    def add_constraint(self,ctype):
        """
        Adds constraint to optimization problem.
        
        Parameters
        ----------
        ctype : int (:ref:`ref_constr_type`)
        """

        cprob.PROB_add_constr(self._c_prob,ctype)

    def add_function(self,ftype,weight):
        """
        Adds function to optimization problem objective.

        Parameters
        ----------
        ftype : int (:ref:`ref_func_type`)
        weight : float
        """

        cprob.PROB_add_func(self._c_prob,ftype,weight)

    def add_heuristic(self,htype):

        cprob.PROB_add_heur(self._c_prob,htype)

    def analyze(self):
        """
        Analyzes function and constraint structures and allocates
        required vectors and matrices.
        """

        cprob.PROB_analyze(self._c_prob)

    def apply_heuristics(self,var_values):
        cdef np.ndarray[double,mode='c'] x = var_values
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if var_values.size else NULL
        cprob.PROB_apply_heuristics(self._c_prob,v)

    def clear(self):
        """
        Resets optimization problem data.
        """

        cprob.PROB_clear(self._c_prob)

    def combine_H(self,coeff,ensure_psd):
        """
        Forms and saves a linear combination of the individual constraint Hessians.

        Parameters
        ----------
        coeff : :class:`ndarray <numpy.ndarray>`
        ensure_psd : {``True``, ``False``}
        """
        
        cdef np.ndarray[double,mode='c'] x = coeff
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if coeff.size else NULL
        cprob.PROB_combine_H(self._c_prob,v,ensure_psd)

    def eval(self,var_values):
        """
        Evaluates objective function and constraints as well as their first and
        second derivatives using the given variable values. 
        
        Parameters
        ----------
        var_values : :class:`ndarray <numpy.ndarray>`
        """
        
        cdef np.ndarray[double,mode='c'] x = var_values
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if var_values.size else NULL
        cprob.PROB_eval(self._c_prob,v)

    def store_sensitivities(self,sens):
        """
        Stores Lagrange multiplier estimates of the nonlinear equality constraint in 
        the power network components.

        Parameters
        ----------
        sens : :class:`ndarray <numpy.ndarray>`
        """
        
        cdef np.ndarray[double,mode='c'] x = sens
        cdef cvec.Vec* v = cvec.VEC_new_from_array(&(x[0]),len(x)) if sens.size else NULL
        cprob.PROB_store_sens(self._c_prob,v)
        if cprob.PROB_has_error(self._c_prob):
            raise ProblemError(cprob.PROB_get_error_string(self._c_prob))

    def find_constraint(self,type):
        """
        Finds constraint of give type among the constraints of this optimization problem.

        Parameters
        ----------
        type : int (:ref:`ref_constr_type`)
        """
        
        cdef cnet.Net* n = cprob.PROB_get_network(self._c_prob)
        c = cprob.PROB_find_constr(self._c_prob,type)
        if c is not NULL:
            return new_Constraint(c,n)
        else:
            raise ProblemError('constraint not found')

    def __dealloc__(self):
        """
        Frees problem C data structure. 
        """
        
        if self.alloc:
            cprob.PROB_del(self._c_prob)
            self._c_prob = NULL

    def get_init_point(self):
        """
        Gets initial solution estimate from the current value of the network variables.

        Returns
        -------
        point : :class:`ndarray <numpy.ndarray>`
        """

        return Vector(cprob.PROB_get_init_point(self._c_prob))

    def get_network(self):
        """
        Gets the power network associated with this optimization problem.
        """

        return new_Network(cprob.PROB_get_network(self._c_prob))

    def set_network(self,net):
        """
        Sets the power network associated with this optimization problem.
        """
        
        cdef Network n = net
        cprob.PROB_set_network(self._c_prob,n._c_net)

    def show(self):
        """
        Shows information about this optimization problem.
        """
        
        cprob.PROB_show(self._c_prob)

    def update_lin(self):
        """
        Updates linear equality constraints.
        """

        cprob.PROB_update_lin(self._c_prob)

    property network:
        """ Power network associated with this optimization problem (:class:`Network <pfnet.Network>`). """
        def __get__(self): return new_Network(cprob.PROB_get_network(self._c_prob))
        def __set__(self,net):
            cdef Network n = net
            cprob.PROB_set_network(self._c_prob,n._c_net)
        
    property constraints:
        """ List of :class:`constraints <pfnet.Constraint>` of this optimization problem (list). """
        def __get__(self):
            clist = []
            cdef cconstr.Constr* c = cprob.PROB_get_constr(self._c_prob)
            cdef cnet.Net* n = cprob.PROB_get_network(self._c_prob)
            while c is not NULL:
                clist.append(new_Constraint(c,n))
                c = cconstr.CONSTR_get_next(c)
            return clist

    property functions:
        """ List of :class:`functions <pfnet.Function>` that form the objective function of this optimization problem (list). """
        def __get__(self):
            flist = []
            cdef cfunc.Func* f = cprob.PROB_get_func(self._c_prob)
            cdef cnet.Net* n = cprob.PROB_get_network(self._c_prob)
            while f is not NULL:
                flist.append(new_Function(f,n))
                f = cfunc.FUNC_get_next(f)
            return flist
            
    property A:
        """ Constraint matrix of linear equality constraints (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cprob.PROB_get_A(self._c_prob))

    property Z:
        """ Matrix whose columns are a basis for the null space of A (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): 
            Z = Matrix(cprob.PROB_get_Z(self._c_prob))
            if cprob.PROB_has_error(self._c_prob):
                raise ProblemError(cprob.PROB_get_error_string(self._c_prob))
            else:
                return Z

    property b:
        """ Right hand side vectors of the linear equality constraints (:class:`ndarray <numpy.ndarray>`). """
        def __get__(self): return Vector(cprob.PROB_get_b(self._c_prob))

    property J:
        """ Jacobian matrix of the nonlinear equality constraints (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cprob.PROB_get_J(self._c_prob))

    property f:
        """ Vector of nonlinear equality constraints violations (:class:`ndarray <numpy.ndarray>`). """
        def __get__(self): return Vector(cprob.PROB_get_f(self._c_prob))

    property phi:
        """ Objective function value (float). """
        def __get__(self): return cprob.PROB_get_phi(self._c_prob)
            
    property gphi:
        """ Objective function gradient vector (:class:`ndarray <numpy.ndarray>`). """
        def __get__(self): return Vector(cprob.PROB_get_gphi(self._c_prob))

    property Hphi:
        """ Objective function Hessian matrix (only the lower triangular part) (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cprob.PROB_get_Hphi(self._c_prob))

    property H_combined:
        """ Linear combination of Hessian matrices of individual nonlinear equality constraints (only the lower triangular part) (:class:`coo_matrix <scipy.sparse.coo_matrix>`). """
        def __get__(self): return Matrix(cprob.PROB_get_H_combined(self._c_prob))