from parameters import p
cimport constant_parameters as c
cimport libc.math as cmath
from draw_wife cimport Wife
cdef extern from "randn.cc":
    double uniform()
import numpy as np


cdef class Husband:
    def get_capacity(self):
        return self.capacity
    def get_schooling(self):
        return self.schooling
    def get_age(self):
        return self.age
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
        self.hsd = 1
        self.hsg = 0
        self.sc = 0
        self.cg = 0
        self.pc = 0
        self.schooling = 0   # husband schooling, can get values of 0-4
        self.years_of_schooling = 11
        self.exp = 0   # husband experience
        self.exp_2 = 0  # husband experience aquared
        self.emp = 0
        self.capacity = 0
        self.divorce = 0
        self.married = 0
        self.age = 17
        self.kids = 0   # always zero unless single. if married - all kids at women structure
        self.health = 0
        self.home_time_ar = 1
        self.ability_value = 0.0
        self.ability_i = 0
        self.mother_educ = 0
        self.mother_marital = 0
        self.mother_immig = 0

    def __str__(self):
        return "Husband\n\tyears of Schooling: " + str(self.years_of_schooling) + "\n\tSchooling: " + str(self.schooling) + "\n\tSchooling Map: " + str(self.hsd) + "," + str(self.hsg) + \
               "," + str(self.sc) + "," + str(self.cg) + "," + str(self.pc) + \
               "\n\tExperience: " + str(self.exp) + "\n\tAbility: " + str(self.ability_i) + "," + str(self.ability_value) + \
               "\n\tAge: " + str(self.age)  + "\n\tKids: " + str(self.kids)+  \
               "\n\tHealth: " + str(self.health)+ "\n\tDivorce: " + str(self.divorce)+  \
               "\n\tmother education: " + str(self.mother_educ) + "\n\tmother marital: " + str(self.mother_marital) + \
               "\n\tCapacity: " + str(self.capacity) + "\n\tEmployment: " + str(self.emp)


cpdef update_school(Husband husband):         # this function update education in Husnabds structures
    if husband.schooling == 0:
        husband.hsd = 1
        husband.hsg = 0
        husband.sc = 0
        husband.cg = 0
        husband.pc = 0
    elif husband.schooling == 1:
        husband.hsg = 1
        husband.hsd = 0
        husband.sc = 0
        husband.cg = 0
        husband.pc = 0
    elif husband.schooling == 2:
        husband.sc = 1
        husband.hsg = 0
        husband.hsd = 0
        husband.cg = 0
        husband.pc = 0
    elif husband.schooling == 3:
        husband.cg = 1
        husband.hsg = 0
        husband.hsd = 0
        husband.sc = 0
        husband.pc = 0
    elif husband.schooling == 4:
        husband.pc = 1
        husband.hsg = 0
        husband.hsd = 0
        husband.sc = 0
        husband.cg = 0
    else:
        assert False

cpdef update_mother_char(Husband husband, double mother0, double mother1, double mother2):
    cdef double temp
    temp = uniform()*100  # draw wife's parents information + relevant child benefit
    if temp < mother0:
        husband.mother_educ = 0
        husband.mother_marital = 0
    elif temp < mother1:
        husband.mother_educ = 0
        husband.mother_marital = 1
    elif temp < mother2:
        husband.mother_educ = 1
        husband.mother_marital = 0
    else:
        husband.mother_educ = 1
        husband.mother_marital = 1
    return


cpdef update_ability_forward(Husband husband):
    cdef double temp_high_ability
    cdef double temp_medium_ability
    cdef double prob_high_ability
    cdef double prob_medium_ability
    cdef double temp
    temp_high_ability = p.ab_high1 + p.ab_high2 * husband.mother_educ + p.ab_high3 * husband.mother_marital
    temp_medium_ability = p.ab_medium1 + p.ab_medium2 * husband.mother_educ + p.ab_medium3 * husband.mother_marital
    prob_high_ability = cmath.exp(temp_high_ability) / (1 + cmath.exp(temp_high_ability) + (temp_medium_ability))
    prob_medium_ability = cmath.exp(temp_medium_ability) / (1 + cmath.exp(temp_high_ability) + cmath.exp(temp_medium_ability))
    temp = uniform()
    if temp < prob_high_ability:
        husband.ability_i = 2
        husband.ability_value = c.normal_vector[2] * p.sigma_ability_h
    elif temp < prob_medium_ability + prob_high_ability:
        husband.ability_i = 1
        husband.ability_value = c.normal_vector[1] * p.sigma_ability_h
    else:
        husband.ability_i = 0
        husband.ability_value = c.normal_vector[0] * p.sigma_ability_h
    return

cpdef update_ability_back(Husband husband):
    if husband.mother_educ ==1 and husband.mother_marital == 1:
        husband.ability_i = 2
        husband.ability_value = c.normal_vector[2] * p.sigma_ability_h
    elif husband.mother_educ == 0 and husband.mother_marital == 0:
        husband.ability_i = 0
        husband.ability_value = c.normal_vector[0] * p.sigma_ability_h
    else:
        husband.ability_i = 1
        husband.ability_value = c.normal_vector[1] * p.sigma_ability_h



cpdef Husband draw_husband(Wife wife, double mother0, double mother1, double mother2):
    cdef Husband result = Husband()
    result.age = wife.age
    update_mother_char(result, mother0, mother1, mother2)
    # update ability by mother education and marital status
    update_ability_forward(result)
    cdef double temp
    cdef double temp1
    cdef double match_cg
    cdef double match_sc
    if wife.age < 18:
        result.schooling = 0   # husband hsd
    elif wife.age < 20:
        result.schooling = 1   # husband hsg
    else:
        if wife.schooling < 2:  # wife is HSD or HSG
            match_cg = cmath.exp(p.omega6_w + p.omega8_w) / (
                1.0 + cmath.exp(p.omega6_w + p.omega8_w) + cmath.exp(p.omega9_w + p.omega10_w))  # probability of meeting cg if hs
            match_sc = cmath.exp(p.omega9_w + p.omega10_w) / (
                1.0 + cmath.exp(p.omega6_w + p.omega8_w) + cmath.exp(p.omega9_w + p.omega10_w))  # probability of meeting sc if hs
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w + p.omega6_w) + np.exp(p.omega7_w + p.omega8_w))  # probability of meeting hs if hs
        elif wife.schooling == 2:
            match_cg = cmath.exp(p.omega6_w + p.omega7_w) / (
                1.0 + cmath.exp(p.omega6_w + p.omega7_w) + cmath.exp(p.omega9_w))  # probability of meeting cg if sc
            match_sc = cmath.exp(p.omega9_w) / (
                1.0 + cmath.exp(p.omega6_w + p.omega7_w) + cmath.exp(p.omega9_w))  # probability of meeting sc if sc
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w + p.omega5_w) + np.exp(p.omega7_w))  # probability of meeting hs if sc
        elif wife.schooling > 2:
            match_cg = cmath.exp(p.omega6_w) / (1.0 + cmath.exp(p.omega6_w) + cmath.exp(p.omega9_w))  # probability of meeting cg if cg
            match_sc = cmath.exp(p.omega9_w) / (1.0 + cmath.exp(p.omega6_w) + cmath.exp(p.omega9_w))  # probability of meeting sc if cg
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w) + np.exp(p.omega7_w))  # probability of meeting hs if cg
            # draw husband schooling
        temp = uniform()
        if temp < match_cg :
            if wife.schooling == 0:
                temp1 = uniform()
                if temp1 < 0.66:  # fix to right number
                    result.schooling = 3  # cg
                else:
                    result.schooling = 4  # pc
            elif wife.schooling == 1:
                temp1 = uniform()
                if temp1 < 0.75:  # fix to right number
                    result.schooling = 3  # cg
                else:
                    result.schooling = 4  # pc
            elif wife.schooling == 2:
                temp1 = uniform()
                if temp1 < 0.85:  # fix to right number
                    result.schooling = 3  # cg
                else:
                    result.schooling = 4  # pc
            elif wife.schooling == 3:
                temp1 = uniform()
                if temp1 < 0.8:  # fix to right number
                    result.schooling = 3  # cg
                else:
                    result.schooling = 4  # pc
            elif wife.schooling == 4:
                temp1 = uniform()
                if temp1 < 0.6:  # fix to right number
                    result.schooling = 3  # cg
                else:
                    result.schooling = 4  # pc

        elif temp < match_cg + match_sc:
            result.schooling = 2  # sc
        else:
            if wife.schooling ==0:
                temp1 = uniform()
                if temp1 < 0.43:  # fix to right number
                    result.schooling = 1  # hsg
                else:
                    result.schooling = 0  # hsd
            elif wife.schooling == 1:
                temp1 = uniform()
                if temp1 < 0.9:  # fix to right number
                    result.schooling = 1  # hsg
                else:
                    result.schooling = 0  # hsd
            elif wife.schooling == 2:
                temp1 = uniform()
                if temp1 < 0.95:  # fix to right number
                    result.schooling = 1  # hsg
                else:
                    result.schooling = 0  # hsd
            elif wife.schooling == 3:
                temp1 = uniform()
                if temp1 < 0.95:  # fix to right number
                    result.schooling = 1  # hsg
                else:
                    result.schooling = 0  # hsd
            elif wife.schooling == 4:
                temp1 = uniform()
                if temp1 < 0.99:  # fix to right number
                    result.schooling = 1  # hsg
                else:
                    result.schooling = 0  # hsd

    update_school(result)
    if result.age >= c.AGE_VALUES[result.schooling]:
        result.exp = result.age - c.AGE_VALUES[result.schooling]
    else:
        result.exp = 0  # if husband is still at school, experience would be zero
    if result.age > 24 :
        result.emp = 1
        result.capacity =1

    return result


cpdef Husband draw_husband_back(Wife wife, double mother0, double mother1, double mother2):
# this function is only used in backward solution for single women
    cdef Husband result = Husband()
    result.age = wife.age
    result.mother_educ = 0
    result.mother_marital = 1
    result.ability_i = 1
    result.ability_value = c.normal_vector[1] * p.sigma_ability_h
    if wife.age < 18:
        result.schooling = 0   # husband hsd
    elif wife.age < 20:
        result.schooling = 1   # husband hsg
    else:
        result.schooling = wife.schooling
    update_school(result)
    if result.age >= c.AGE_VALUES[result.schooling]:
        result.exp = result.age - c.AGE_VALUES[result.schooling]
    else:
        result.exp = 0  # if husband is still at school, experience would be zero
    if result.age > 24 :
        result.emp = 1
        result.capacity =1
    return result
