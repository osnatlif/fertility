import cohorts
# number of draws
cdef int DRAW_B = 1   # DRAW_B = 30 - backword
DRAW_F = 5000         # forward draws
cdef int cohort = int(cohorts.cohort[0:4])
race = cohorts.cohort[4:]

print(cohort)

cdef int max_period = 43  # retirement
full_full_array = [0, 1, 2, 3, 6, 7, 9, 10]
# marriage options:# first index wife, second husband
#            0-married + women unemployed  +man unemployed     +non-pregnant
#                        1-married + women unemployed  +man unemployed     +pregnant
#                        2-married + women unemployed  +man employed full  +non-pregnant
#                        3-married + women unemployed  +man employed full  +pregnant
#                        4-married + women unemployed  +man employed part  +non-pregnant
#                        5-married + women unemployed  +man employed part  +pregnant
#            6-married + women employed full   +man unemployed     +non-pregnant
#                        7-married + women employed full   +man unemployed     +pregnant
#                        8-married + women employed full   +man employed full  +non-pregnant
#                        9-married + women employed full +man employed full  +pregnant
#                        10-married + women employed full +man employed part  +non-pregnant
#                        11-married + women employed full +man employed part  +pregnant
#            12-married + women employed part  +man unemployed     +non-pregnant
#                        13-married + women employed part +man unemployed     +pregnant
#                        14-married + women employed part +man employed full  +non-pregnant
#                        15-married + women employed part +man employed full  +pregnant
#                        16-married + women employed part +man employed part  +non-pregnant
#                        17-married + women employed part  +man employed part  +pregnant
men_full_index_array = [2, 3, 8, 9, 14, 15]
men_part_index_array = [4, 5, 10, 11, 16, 17]
men_unemployed_index_array = [0, 1, 6, 7, 12, 13]
pregnancy_index_array = [1, 3, 5, 7, 9, 11, 13, 15, 17]
single_women_pregnancy_index_array = [1, 3, 5, 8, 10, 12]
single_women_full_time_index_array = [2, 3, 9, 10]
single_women_part_time_index_array = [4, 5, 11, 12]
single_women_welfare_index_array = [7, 8, 9, 10, 11, 12]
single_women_unemployed_index_array = [0, 1, 7, 8]
max_school = 14  # 30 - 17

cdef int NO_KIDS = 0
cdef double beta0 = 0.983  # discount rate
cdef double MINIMUM_UTILITY = float('-inf')
cdef int[:] AGE_VALUES = [18, 18, 20, 22, 25]
cdef int[:] exp_vector = [0, 2, 4, 8, 16]  # experience - 5 point grid
#cdef double[:] home_time_vector = [0.5, 1, 1.5]
cdef double home_time_vector = 1
cdef int ub_h = 16  # UNEMPLOYMENT BENEFIT HUSBAND
cdef int ub_w = 16  # UNEMPLOYMENT BENEFIT WIFE
# work status: (unemp, emp)
cdef int UNEMP = 0
cdef int EMP = 1
cdef int leisure = 18
cdef int leisure_part =8
# ability wife/husband: (low, medium, high)) + match quality: (high, medium, low)
# cdef double[:] normal_vector = [-1.150, 0.0, 1.150]
cdef double[:] normal_vector = [-1.150, 0.0,  1.150]
cdef double[:] ability_vector = [-1.150,  1.150]

# marital status: (unmarried, married)
cdef int UNMARRIED = 0
cdef int MARRIED = 1
# school groups
cdef int school_size = 5
cdef int exp_size = 5
cdef int kids_size = 4    # number of children: (0, 1, 2, 3+)
cdef int ability_size = 1
cdef int home_time_size = 1 #3
cdef int mother_size = 2
cdef int mother_marital_size = 2
cdef int health_size = 1 #1
cdef int mother_educ = 0
cdef int mother_marital = 0
cdef int home_production = 0
# maximum fertility age
cdef int MAX_FERTILITY_AGE = 40
cdef double eta1 = 0.194   # fraction from parents net income  that one kid get
cdef double eta2 = 0.293   # fraction from parents net income that 2 kids get
cdef double eta3 = 0.367   # fraction from parents net  income that 3 kids get
cdef double eta4 = 0.423   # fraction from parents net income  that 4 kids get
cdef double scale = 0.707  # fraction of public consumption
cdef double bp = 0.5       # bargaining power
cdef int GRID = 3
cdef int AGE = 17          # initial age
cdef int GOOD = 0 # health status
cdef int POOR = 1
cdef int constant_welfare = 4000   # before 97
cdef int by_kids_welfare = 1000    # before 97
cdef double by_income_welfare = -0.19  # before 97
cdef double home_p = 0
###########################
#   BY COHORT CONSTANTS   #
###########################
max_1960 = 43
max_1970 = 32
max_1980 = 25
max_1990 = 17

cdef double mother_hispanic_newcommer

if cohort == 1960:
    mother_hispanic_newcommer = 0.1
elif cohort == 1970:
    mother_hispanic_newcommer = 0.1
elif cohort == 1980:
    mother_hispanic_newcommer = 0.1
elif cohort == 1990:
    mother_hispanic_newcommer = 0.1
elif cohort == 2000:
    mother_hispanic_newcommer = 0.1
elif cohort == 2010:
    mother_hispanic_newcommer = 0.1
else:
    assert False, "invalid cohort: " + str(cohort)

#                  M=0,C=0       M=1,C=0        M=0,C=1  M=1,C=1
cdef double[3] mother_1960_white    = [5.48,	86.00,	86.89]
cdef double[3] mother_1970_white    = [8.98,	76.00,	78.83]
cdef double[3] mother_1980_white    = [13.82,	74.00,	78.86]
cdef double[3] mother_1990_white    = [16.49,	62.00,	72.11]
cdef double[3] mother_2000_white    = [11.94,	55.00,	64.77]
cdef double[3] mother_2010_white    = [10.73,	49.00,	60.17]

cdef double[3] mother_1960_black    = [34.81,	94.00,	96.22]
cdef double[3] mother_1970_black    = [43.04,	88.00,	93.87]
cdef double[3] mother_1980_black    = [53.54,	87.00,	95.00]
cdef double[3] mother_1990_black    = [54.75,	81.00,	93.84]
cdef double[3] mother_2000_black    = [46.35,	75.00,	90.45]
cdef double[3] mother_2010_black    = [53.64,	72.00,	92.86]

cdef double[3] mother_1960_hispanic = [11.83,	93.00,	93.89]
cdef double[3] mother_1970_hispanic = [17.11,	92.00,	93.49]
cdef double[3] mother_1980_hispanic = [23.03,	89.00,	91.85]
cdef double[3] mother_1990_hispanic = [26.70,	86.00,	90.35]
cdef double[3] mother_2000_hispanic = [27.56,	83.00,	88.64]
cdef double[3] mother_2010_hispanic = [30.80,	77.00,	86.20]

cdef double cb_const
cdef double cb_per_child

if cohort == 1960:
    cb_const = 4317.681 # child benefit for single mom + 1 kid - annually
    cb_per_child = 1517.235
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

cdef double[3] mother

if race == "white":
    if cohort == 1960:
        mother = mother_1960_white
    elif cohort == 1970:
        mother = mother_1970_white
    elif cohort == 1980:
        mother = mother_1980_white
    elif cohort == 1990:
        mother = mother_1990_white
    elif cohort == 2000:
        mother = mother_2000_white
    elif cohort == 2010:
        mother = mother_2010_white
    else:
        assert False, "invalid cohort: " + str(cohort)
elif race == "black":
    if cohort == 1960:
        mother = mother_1960_black
    elif cohort == 1970:
        mother = mother_1970_black
    elif cohort == 1980:
        mother = mother_1980_black
    elif cohort == 1990:
        mother = mother_1990_black
    elif cohort == 2000:
        mother = mother_2000_black
    elif cohort == 2010:
        mother = mother_2010_black
    else:
        assert False, "invalid cohort: " + str(cohort)
elif race == "hispanic":
    if cohort == 1960:
        mother = mother_1960_hispanic
    elif cohort == 1970:
        mother = mother_1970_hispanic
    elif cohort == 1980:
        mother = mother_1980_hispanic
    elif cohort == 1990:
        mother = mother_1990_hispanic
    elif cohort == 2000:
        mother = mother_2000_hispanic
    elif cohort == 2010:
        mother = mother_2010_hispanic
    else:
        assert False, "invalid cohort: " + str(cohort)
else:
    assert False, "invalid race: " + race

max_period_f = max_period
exp_size_f = exp_size
kids_size_f = kids_size
health_size_f = health_size
home_time_size_f = home_time_size
school_size_f = school_size
ability_size_f = ability_size
mother_size_f = mother_size
max_school_f = max_school
cohort_f = cohort
mother_f = mother
bp_f = bp