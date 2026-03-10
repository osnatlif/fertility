import numpy as np
from parameters import p
cimport constant_parameters as c
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
from draw_husband cimport Husband

# wives = np.loadtxt("wives.out")

cdef class Wife:
    def get_age(self):
        return self.age
    def get_schooling(self):
        return self.schooling
    def get_on_welfare(self):
        return self.on_welfare
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
        # following are indicators for the wife's schooling they have values of 0/1 and only one of them could be 1
        self.hsd = 1
        self.hsg = 0
        self.sc = 0
        self.cg = 0
        self.pc = 0
        self.schooling = 0    # wife schooling, can get values of 0-4
        self.years_of_schooling = 11
        self.exp = 0    # wife experience
        self.exp_2 = 0  # wife experience aquared
        self.emp = 0    # wife employment state !!!
        self.capacity = 0
        self.married = 0
        self.divorce = 0
        self.age = 17
        self.kids = 0      # wife's kids
        self.health = 0
        self.preg = 0
        self.home_time_ar = 1
        self.ability_value = 0
        self.ability_i = 0
        self.mother_educ = 0
        self.mother_marital = 0
        self.mother_immig = 0
        self.on_welfare = 0
        self.welfare_periods = 0
        self.age_first_child = 0
        self.age_second_child = 0
        self.age_third_child = 0
        self.match_quality = 0
    def __str__(self):
        return "Wife\n\tyears of Schooling: " + str(self.years_of_schooling) + "\n\tSchooling: " + str(self.schooling) + "\n\tSchooling Map: " + str(self.hsd) + "," + str(self.hsg) + \
               "," + str(self.sc) + "," + str(self.cg) + "," + str(self.pc) + \
               "\n\tExperience: " + str(self.exp) + "\n\tAbility: " + str(self.ability_i) + "," + str(self.ability_value) + \
               "\n\tAge: " + str(self.age)  + "\n\tKids: " + str(self.kids)+ "\n\tage first kid: " + str(self.age_first_child) + \
               "\tage second child: " + str(self.age_second_child) + "\tage third child: " + str(self.age_third_child) + \
               "\n\tHealth: " + str(self.health)+ "\n\tDivorce: " + str(self.divorce)+  \
               "\n\tPregnant: " + str(self.preg) + "\n\tmother education: " + str(self.mother_educ) + "\n\tmother marital: " + str(self.mother_marital) + \
               "\n\tCapacity: " + str(self.capacity) + "\n\tEmployment: " + str(self.emp)


cpdef update_wife_schooling(Wife wife):
    if wife.schooling == 0:
        wife.hsd = 1
        wife.hsg = 0
        wife.sc = 0
        wife.cg = 0
        wife.pc = 0
    elif wife.schooling == 1:
        wife.hsd = 0
        wife.hsg = 1
        wife.sc = 0
        wife.cg = 0
        wife.pc = 0
    elif wife.schooling == 2:
        wife.hsd = 0
        wife.hsg = 0
        wife.sc = 1
        wife.cg = 0
        wife.pc = 0
    elif wife.schooling == 3:
        wife.hsd = 0
        wife.hsg = 0
        wife.sc = 0
        wife.cg = 1
        wife.pc = 0
    elif wife.schooling == 4:
        wife.hsd = 0
        wife.hsg = 0
        wife.sc = 0
        wife.cg = 0
        wife.pc = 1
    else:
        assert False

cpdef update_mother_char(Wife wife, double mother0, double mother1, double mother2):
    cdef double temp
    temp = uniform()*100  # draw wife's parents information + relevant child benefit
    if temp < mother0:
        wife.mother_educ = 0
        wife.mother_marital = 0
    elif temp < mother1:
        wife.mother_educ = 0
        wife.mother_marital = 1
    elif temp < mother2:
        wife.mother_educ = 1
        wife.mother_marital = 0
    else:
        wife.mother_educ = 1
        wife.mother_marital = 1
    return




cpdef update_ability_forward(Wife wife):
    cdef double temp_high_ability
    cdef double temp_medium_ability
    cdef double prob_high_ability
    cdef double prob_medium_ability
    cdef double temp
    temp_high_ability = p.ab_high1 + p.ab_high2 * wife.mother_educ + p.ab_high3 * wife.mother_marital
    temp_medium_ability = p.ab_medium1 + p.ab_medium2 * wife.mother_educ + p.ab_medium3 * wife.mother_marital
    prob_high_ability = cmath.exp(temp_high_ability) / (1 + cmath.exp(temp_high_ability) + (temp_medium_ability))
    prob_medium_ability = cmath.exp(temp_medium_ability) / (1 + cmath.exp(temp_high_ability) + cmath.exp(temp_medium_ability))
    temp = uniform()
    if temp < prob_high_ability:
        wife.ability_i = 2
        wife.ability_value = c.normal_vector[2] * p.sigma_ability_w
    elif temp < prob_medium_ability + prob_high_ability:
        wife.ability_i = 1
        wife.ability_value = c.normal_vector[1] * p.sigma_ability_w
    else:
        wife.ability_i = 0
        wife.ability_value = c.normal_vector[0] * p.sigma_ability_w
    return

cpdef update_ability_back(Wife wife):
    if wife.mother_educ ==1 and wife.mother_marital == 1:
        wife.ability_i = 2
        wife.ability_value = c.normal_vector[2] * p.sigma_ability_w
    elif wife.mother_educ == 0 and wife.mother_marital == 0:
        wife.ability_i = 0
        wife.ability_value = c.normal_vector[0] * p.sigma_ability_w
    else:
        wife.ability_i = 1
        wife.ability_value = c.normal_vector[1] * p.sigma_ability_w

cpdef Wife draw_wife(Husband husband, double mother0, double mother1, double mother2):
    cdef Wife result = Wife()
    result.age = husband.age
    update_ability_forward(result)
    update_mother_char(result, mother0, mother1, mother2)

    # update ability by mother education and marital status
    cdef double temp
    cdef double temp1
    cdef double match_cg
    cdef double match_sc
    if husband.age < 18:
        result.schooling = 0   # husband hsd
    elif husband.age < 20:
        result.schooling = 1   # husband hsg
    else:
        if husband.schooling < 2:  # wife is HSD or HSG
            match_cg = cmath.exp(p.omega6_h + p.omega8_h) / (
                1.0 + cmath.exp(p.omega6_h + p.omega8_h) + cmath.exp(p.omega9_h + p.omega10_h))  # probability of meeting cg if hs
            match_sc = cmath.exp(p.omega9_h + p.omega10_h) / (
                1.0 + cmath.exp(p.omega6_h + p.omega8_h) + cmath.exp(p.omega9_h + p.omega10_h))  # probability of meeting sc if hs
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w + p.omega6_w) + np.exp(p.omega7_w + p.omega8_w))  # probability of meeting hs if hs
        elif husband.schooling == 2:
            match_cg = cmath.exp(p.omega6_h + p.omega7_h) / (
                1.0 + cmath.exp(p.omega6_h + p.omega7_h) + cmath.exp(p.omega9_h))  # probability of meeting cg if sc
            match_sc = cmath.exp(p.omega9_h) / (
                1.0 + cmath.exp(p.omega6_h + p.omega7_h) + cmath.exp(p.omega9_h))  # probability of meeting sc if sc
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w + p.omega5_w) + np.exp(p.omega7_w))  # probability of meeting hs if sc
        elif husband.schooling > 2:
            match_cg = cmath.exp(p.omega6_h) / (1.0 + cmath.exp(p.omega6_h) + cmath.exp(p.omega9_h))  # probability of meeting cg if cg
            match_sc = cmath.exp(p.omega9_h) / (1.0 + cmath.exp(p.omega6_h) + cmath.exp(p.omega9_h))  # probability of meeting sc if cg
            # match_hsg = 1.0 / (1.0 + np.exp(p.omega4_w) + np.exp(p.omega7_w))  # probability of meeting hs if cg
        # draw husband schooling
        temp = uniform()
        if temp < match_cg:
            temp1 = uniform()
            if temp1 < 0.9:  # fix to right number
                result.schooling = 3  # cg
            else:
                result.schooling = 4  # pc
        elif temp < match_cg + match_sc:
            result.schooling = 2  # sc
        else:
            temp1 = uniform()
            if temp1 < 0.8:  # fix to right number
                result.schooling = 1  # hsg
            else:
                result.schooling = 0  # hsd
    update_wife_schooling(result)
    if result.age >= c.AGE_VALUES[result.schooling]:
        result.exp = result.age - c.AGE_VALUES[result.schooling]
    else:
        result.exp = 0  # if husband is still at school, experience would be zero
    if result.age > 24 :
        result.emp = 1
        result.capacity =1

    return result


cpdef Wife draw_wife_back(Husband husband, double mother0, double mother1, double mother2):
# this function is used in backward solving for single men only!
    cdef Wife result = Wife()
    result.age = husband.age
    result.mother_marital = 1
    result.mother_educ = 0
    result.ability_i = 1
    result.ability_value = c.normal_vector[1] * p.sigma_ability_w    # update ability by mother education and marital status
    if husband.age < 18:
        result.schooling = 0  # husband hsd
    elif husband.age < 20:
        result.schooling = 1  # husband hsg
    else:
        result. schooling =  husband.schooling
    update_wife_schooling(result)
    if result.age >= c.AGE_VALUES[result.schooling]:
        result.exp = result.age - c.AGE_VALUES[result.schooling]
    else:
        result.exp = 0  # if husband is still at school, experience would be zero
    if result.age > 24 :
        result.emp = 1
        result.capacity =1
    return result
