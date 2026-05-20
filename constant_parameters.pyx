import numpy as np
import cohorts
# number of draws
cdef int DRAW_B = 30   # DRAW_B = 30 - backword
DRAW_F = 5000         # forward draws
cdef int cohort = int(cohorts.cohort[0:4])
race = cohorts.cohort[4:]

print(cohort)

cdef int max_period = 34  # retirement (t=1..33 -> ages 18..50)
full_full_array = [0, 1, 2, 3, 6, 7, 9, 10]
# marriage options:# first index wife, second husband
#        0-married + women unemployed  +man unemployed     +non-pregnant
#        1-married + women unemployed  +man unemployed     +pregnant
#        2-married + women unemployed  +man employed full  +non-pregnant
#        3-married + women unemployed  +man employed full  +pregnant
#        4-married + women unemployed  +man employed part  +non-pregnant
#        5-married + women unemployed  +man employed part  +pregnant
#        6-married + women employed full   +man unemployed     +non-pregnant
#        7-married + women employed full   +man unemployed     +pregnant
#        8-married + women employed full   +man employed full  +non-pregnant
#        9-married + women employed full +man employed full  +pregnant
#        10-married + women employed full +man employed part  +non-pregnant
#        11-married + women employed full +man employed part  +pregnant
#        12-married + women employed part  +man unemployed     +non-pregnant
#        13-married + women employed part +man unemployed     +pregnant
#        14-married + women employed part +man employed full  +non-pregnant
#        15-married + women employed part +man employed full  +pregnant
#        16-married + women employed part +man employed part  +non-pregnant
#        17-married + women employed part  +man employed part  +pregnant
men_full_index_array = [2, 3, 8, 9, 14, 15]
men_part_index_array = [4, 5, 10, 11, 16, 17]
men_unemployed_index_array = [0, 1, 6, 7, 12, 13]
pregnancy_index_array = [1, 3, 5, 7, 9, 11, 13, 15, 17]
single_women_pregnancy_index_array = [1, 3, 5]
single_women_full_time_index_array = [2, 3]
single_women_part_time_index_array = [4, 5]
single_women_unemployed_index_array = [0, 1]

cdef int NO_KIDS = 0
cdef double beta0 = 0.983  # discount rate
cdef double MINIMUM_UTILITY = float('-inf')
cdef int[3] AGE_VALUES
AGE_VALUES[0] = 18  # HS
AGE_VALUES[1] = 20  # SC
AGE_VALUES[2] = 22  # CG+
cdef int ub_h = 8000  # UNEMPLOYMENT BENEFIT HUSBAND (annual)
cdef int ub_w = 6000  # UNEMPLOYMENT BENEFIT WIFE (annual)
# work status: (unemp, emp)
cdef int UNEMP = 0
cdef int EMP = 1
cdef double leisure = 1
cdef double leisure_part = 0.5
cdef double home_p = 0

# ability wife/husband: (low, medium, high)) + match quality: (high, medium, low)
cdef double[:] normal_vector = [-1.150, 0.0,  1.150]
cdef double[:] ability_vector = [-1.150, 0.0, 1.150]
cdef double[3] match_vector = [-1.150, 0.0, 1.150]

# marital status: (unmarried, married)
cdef int UNMARRIED = 0
cdef int MARRIED = 1
# school groups
cdef int school_size = 3  # 0=HS (high school or less), 1=SC (some college), 2=CG+ (college graduate+)
cdef int kids_size = 4    # number of children: (0, 1, 2, 3+)
cdef int kids_below_5_size = 4  # number of children below 5: (0, 1, 2, 3)
cdef int ability_size = 3
cdef int emp_size = 2     # employed in previous period: (0=NO, 1=YES)
cdef int match_quality_size = 3  # match quality: (LOW, MEDIUM, HIGH)

# maximum fertility age
cdef int MAX_FERTILITY_AGE = 45
cdef double eta1 = 0.194   # fraction from parents net income  that one kid get
cdef double eta2 = 0.293   # fraction from parents net income that 2 kids get
cdef double eta3 = 0.367   # fraction from parents net  income that 3 kids get
cdef double eta4 = 0.423   # fraction from parents net income  that 4 kids get
cdef double scale = 0.707  # fraction of public consumption
cdef double bp = 0.5       # bargaining power
cdef int GRID = 3
cdef int AGE = 18          # initial age
cdef int constant_welfare = 4000   # before 97
cdef int by_kids_welfare = 1000    # before 97
cdef double by_income_welfare = -0.19  # before 97
###########################
#   BY COHORT CONSTANTS   #
###########################
max_1960 = 30   # periods 0-29, ages 17-46, covers all 5 age groups
max_1985 = 30   # same for 1985 cohort
N_AGE_GROUPS = 5
# age groups: 22-26, 27-31, 32-36, 37-41, 42-46
# corresponding to periods: 5-9, 10-14, 15-19, 20-24, 25-29

cdef double cb_const
cdef double cb_per_child

if cohort == 1960:
    cb_const = 4317.681 # child benefit for single mom + 1 kid - annually
    cb_per_child = 1517.235
elif cohort == 1985:
    cb_const = 4530.784 # child benefit for single mom + 1 kid - annually
    cb_per_child = 975.3533
elif cohort == 1970:
    cb_const = 4749.394 # child benefit for single mom + 1 kid - annually
    cb_per_child = 1179.676
elif cohort == 1980:
    cb_const = 4530.784 # child benefit for single mom + 1 kid - annually
    cb_per_child = 975.3533
elif cohort == 1990:
    cb_const = 4530.784 # child benefit for single mom + 1 kid - annually
    cb_per_child = 975.3533
elif cohort == 2000:
    cb_const = 4530.784 # child benefit for single mom + 1 kid - annually
    cb_per_child = 975.3533
elif cohort == 2010:
    cb_const = 4530.784 # child benefit for single mom + 1 kid - annually
    cb_per_child = 975.3533
else:
    assert False, "invalid cohort: " + str(cohort)

max_period_f = max_period
kids_size_f = kids_size
kids_below_5_size_f = kids_below_5_size
school_size_f = school_size
ability_size_f = ability_size
emp_size_f = emp_size
match_quality_size_f = match_quality_size
cohort_f = cohort
bp_f = bp
N_AGE_GROUPS_f = N_AGE_GROUPS
AGE_VALUES_f = [18, 20, 22]  # entry ages for 3 education levels: HS, SC, CG+
MAX_FERTILITY_AGE_f = MAX_FERTILITY_AGE
# Python-accessible copy of preg_prob; populated below after the cdef array is filled
preg_prob_f = None

# pregnancy probability by age (index 0 = age 18, index 1 = age 19, ..., index 26 = age 44)
_preg_prob_data = np.loadtxt("input/preg_prob" + cohorts.cohort + ".txt")
cdef double[39] preg_prob
for _i in range(39):
    preg_prob[_i] = _preg_prob_data[_i]
preg_prob_f = _preg_prob_data.copy()

# childcare cost per child below 5 (annual) - applies when mother works full-time or part-time
cdef double childcare_cost = 5000.0

# Gauss-Hermite quadrature nodes/weights for integrating against N(0,1).
# E[f(Z)] for Z ~ N(0,1) is approximately sum_i gh_weights[i] * f(gh_nodes[i]).
# For ε ~ N(0, σ²): use σ*gh_nodes[i] in place of f's argument.
# Exact for polynomials of degree <= 2*N_GH-1.
cdef int N_GH = 3         # nodes for `temp` (match-quality residual) integration
cdef int N_GH_PREG = 3    # nodes for `temp_preg` (pregnancy preference) integration
cdef double[3] gh_nodes
cdef double[3] gh_weights
cdef double[3] gh_nodes_preg
cdef double[3] gh_weights_preg
_gh_x, _gh_w = np.polynomial.hermite_e.hermegauss(3)
# hermegauss integrates against exp(-x^2/2), so divide by sqrt(2*pi) to get
# the standard-normal expectation (weights then sum to 1).
_norm = np.sqrt(2.0 * np.pi)
for _i in range(3):
    gh_nodes[_i] = _gh_x[_i]
    gh_weights[_i] = _gh_w[_i] / _norm
_gh_x_p, _gh_w_p = np.polynomial.hermite_e.hermegauss(3)
for _i in range(3):
    gh_nodes_preg[_i] = _gh_x_p[_i]
    gh_weights_preg[_i] = _gh_w_p[_i] / _norm