from parameters import p
cimport constant_parameters as c
cimport libc.math as cmath
from draw_wife cimport Wife
from cohorts import cohort
cdef extern from "randn.cc":
    double uniform()
import numpy as np

# load male education distribution by age: columns are age, P(HS), P(SC), P(CG+)
_edu_dist_m = np.loadtxt("input/education_dist_m" + cohort + ".txt")


cdef class Husband:
    def get_capacity(self):
        return self.capacity
    def get_schooling(self):
        return self.schooling
    def get_age(self):
        return self.age
    def set_age(self, int value):
        self.age = value
    def get_kids(self):
        return self.kids
    def get_divorce(self):
        return self.divorce
    def get_capacity(self):
        return self.capacity
    def get_married(self):
        return self.married
    def set_divorce(self, state):
        self.divorce = state
    def __init__(self):
        self.hs = 1
        self.sc = 0
        self.cg = 0
        self.schooling = 0   # husband schooling, can get values of 0-2
        self.years_of_schooling = 11
        self.emp = 0
        self.capacity = 0
        self.divorce = 0
        self.married = 0
        self.age = 17
        self.kids = 0   # always zero unless single. if married - all kids at women structure
        self.ability_value = 0.0
        self.ability_i = 0
        self.mother_educ = 0
        self.mother_marital = 0
        self.mother_immig = 0

    def __str__(self):
        return "Husband\n\tyears of Schooling: " + str(self.years_of_schooling) + "\n\tSchooling: " + str(self.schooling) + "\n\tSchooling Map: " + str(self.hs) + \
               "," + str(self.sc) + "," + str(self.cg) + \
               "\n\tAbility: " + str(self.ability_i) + "," + str(self.ability_value) + \
               "\n\tAge: " + str(self.age)  + "\n\tKids: " + str(self.kids)+  \
               "\n\tDivorce: " + str(self.divorce)+  \
               "\n\tmother education: " + str(self.mother_educ) + "\n\tmother marital: " + str(self.mother_marital) + \
               "\n\tCapacity: " + str(self.capacity) + "\n\tEmployment: " + str(self.emp)


cpdef update_school(Husband husband):         # this function update education in Husbands structures
    # 3 education levels: 0=HS (high school or less), 1=SC (some college), 2=CG+ (college graduate+)
    if husband.schooling == 0:  # HS
        husband.hs = 1
        husband.sc = 0
        husband.cg = 0
    elif husband.schooling == 1:  # SC
        husband.hs = 0
        husband.sc = 1
        husband.cg = 0
    elif husband.schooling == 2:  # CG+
        husband.hs = 0
        husband.sc = 0
        husband.cg = 1
    else:
        assert False



cpdef update_ability_forward(Husband husband):
    # uniform 1/3 over (low, medium, high)
    cdef double temp = uniform()
    if temp < 1.0/3.0:
        husband.ability_i = 0
        husband.ability_value = c.normal_vector[0] * p.sigma_ability_h
    elif temp < 2.0/3.0:
        husband.ability_i = 1
        husband.ability_value = c.normal_vector[1] * p.sigma_ability_h
    else:
        husband.ability_i = 2
        husband.ability_value = c.normal_vector[2] * p.sigma_ability_h
    return

cpdef update_ability_back(Husband husband):
    husband.ability_i = 1
    husband.ability_value = c.normal_vector[1] * p.sigma_ability_h



cpdef Husband draw_husband(Wife wife):
    cdef Husband result = Husband()
    result.age = wife.age
    update_ability_forward(result)
    # draw husband education from male education distribution by age
    cdef int age_idx = <int>result.age - 18
    cdef double prob_hs = _edu_dist_m[age_idx, 1]
    cdef double prob_sc = _edu_dist_m[age_idx, 2]
    cdef double temp = uniform()
    if temp < prob_hs:
        result.schooling = 0  # HS
    elif temp < prob_hs + prob_sc:
        result.schooling = 1  # SC
    else:
        result.schooling = 2  # CG+
    update_school(result)
    if result.age > 24:
        result.emp = 1
        result.capacity = 1

    return result


cpdef Husband draw_husband_back(Wife wife):
# this function is only used in backward solution for single women
    cdef Husband result = Husband()
    result.age = wife.age
    result.ability_i = 1
    result.ability_value = c.normal_vector[1] * p.sigma_ability_h
    # draw husband education from age-specific distribution (same as forward)
    cdef int age_idx = min(<int>result.age - 18, <int>_edu_dist_m.shape[0] - 1)
    cdef double prob_hs = _edu_dist_m[age_idx, 1]
    cdef double prob_sc = _edu_dist_m[age_idx, 2]
    cdef double temp = uniform()
    if temp < prob_hs:
        result.schooling = 0  # HS
    elif temp < prob_hs + prob_sc:
        result.schooling = 1  # SC
    else:
        result.schooling = 2  # CG+
    update_school(result)
    if result.age > 24 :
        result.emp = 1
        result.capacity =1
    return result


cpdef tuple husband_school_probs(int age):
    # probabilities of husband schooling (HS, SC, CG+) at a given age,
    # from the empirical male education distribution
    cdef int age_idx = min(age - 18, <int>_edu_dist_m.shape[0] - 1)
    if age_idx < 0:
        age_idx = 0
    cdef double prob_hs = _edu_dist_m[age_idx, 1]
    cdef double prob_sc = _edu_dist_m[age_idx, 2]
    cdef double prob_cg = 1.0 - prob_hs - prob_sc
    return prob_hs, prob_sc, prob_cg


cpdef tuple ability_probs():
    # uniform 1/3 over (low, medium, high). Same distribution applies to both
    # husbands and wives -- only the sigma differs in the ability value.
    cdef double third = 1.0 / 3.0
    return third, third, third
