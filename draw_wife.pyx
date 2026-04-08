import numpy as np
from parameters import p
cimport constant_parameters as c
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
from draw_husband cimport Husband
from cohorts import cohort

# load female education distribution by age: columns are age, P(HS), P(SC), P(CG+)
_edu_dist_f = np.loadtxt("input/education_dist_f" + cohort + ".txt")

cdef class Wife:
    def get_age(self):
        return self.age
    def set_age(self, int value):
        self.age = value
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
        self.hs = 1
        self.sc = 0
        self.cg = 0
        self.schooling = 0    # wife schooling, can get values of 0-4
        self.years_of_schooling = 11
        self.emp = 0    # wife employment state !!!
        self.capacity = 0
        self.married = 0
        self.divorce = 0
        self.age = 17
        self.kids = 0      # wife's kids
        self.preg = 0
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
        self.kb5 = 0
        self.match_quality = 0
    def __str__(self):
        return "Wife\n\tyears of Schooling: " + str(self.years_of_schooling) + "\n\tSchooling: " + str(self.schooling) + "\n\tSchooling Map: " + str(self.hs) + \
               "," + str(self.sc) + "," + str(self.cg) + \
               "\n\tAbility: " + str(self.ability_i) + "," + str(self.ability_value) + \
               "\n\tAge: " + str(self.age)  + "\n\tKids: " + str(self.kids)+ "\n\tage first kid: " + str(self.age_first_child) + \
               "\tage second child: " + str(self.age_second_child) + "\tage third child: " + str(self.age_third_child) + \
               "\n\tDivorce: " + str(self.divorce)+  \
               "\n\tPregnant: " + str(self.preg) + "\n\tmother education: " + str(self.mother_educ) + "\n\tmother marital: " + str(self.mother_marital) + \
               "\n\tCapacity: " + str(self.capacity) + "\n\tEmployment: " + str(self.emp)


cpdef update_wife_schooling(Wife wife):
    # 3 education levels: 0=HS (high school or less), 1=SC (some college), 2=CG+ (college graduate+)
    if wife.schooling == 0:  # HS
        wife.hs = 1
        wife.sc = 0
        wife.cg = 0
    elif wife.schooling == 1:  # SC
        wife.hs = 0
        wife.sc = 1
        wife.cg = 0
    elif wife.schooling == 2:  # CG+
        wife.hs = 0
        wife.sc = 0
        wife.cg = 1
    else:
        assert False





cpdef update_ability_forward(Wife wife):
    cdef double temp_high_ability
    cdef double temp_medium_ability
    cdef double prob_high_ability
    cdef double prob_medium_ability
    cdef double temp
    temp_high_ability = p.ab_high
    temp_medium_ability = p.ab_medium
    prob_high_ability = cmath.exp(temp_high_ability) / (1 + cmath.exp(temp_high_ability) + cmath.exp(temp_medium_ability))
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
    wife.ability_i = 1
    wife.ability_value = c.normal_vector[1] * p.sigma_ability_w

cpdef Wife draw_wife(Husband husband):
    cdef Wife result = Wife()
    result.age = husband.age
    update_ability_forward(result)
    # draw wife education from female education distribution by age
    cdef int age_idx = <int>result.age - 18
    cdef double prob_hs = _edu_dist_f[age_idx, 1]
    cdef double prob_sc = _edu_dist_f[age_idx, 2]
    cdef double temp = uniform()
    if temp < prob_hs:
        result.schooling = 0  # HS
    elif temp < prob_hs + prob_sc:
        result.schooling = 1  # SC
    else:
        result.schooling = 2  # CG+
    update_wife_schooling(result)
    if result.age > 24:
        result.emp = 1
        result.capacity = 1

    return result


cpdef Wife draw_wife_back(Husband husband):
# this function is used in backward solving for single men only!
    cdef Wife result = Wife()
    result.age = husband.age
    result.ability_i = 1
    result.ability_value = c.normal_vector[1] * p.sigma_ability_w
    # draw wife education from age-specific female population distribution (same as forward)
    cdef int age_idx = min(<int>result.age - 18, <int>_edu_dist_f.shape[0] - 1)
    cdef double prob_hs = _edu_dist_f[age_idx, 1]
    cdef double prob_sc = _edu_dist_f[age_idx, 2]
    cdef double temp = uniform()
    if temp < prob_hs:
        result.schooling = 0  # HS
    elif temp < prob_hs + prob_sc:
        result.schooling = 1  # SC
    else:
        result.schooling = 2  # CG+
    update_wife_schooling(result)
    if result.age > 24 :
        result.emp = 1
        result.capacity =1
    return result
