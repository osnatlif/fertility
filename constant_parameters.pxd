# number of draws
cdef int DRAW_B
cdef int cohort
cdef int max_period  # retirement
# cdef int[6] men_full_index_array
# cdef int[6] men_part_index_array
# cdef int[6] men_unemployed_index_array
# cdef int[9] pregnancy_index_array
# cdef int[6] single_women_pregnancy_index_array
# cdef int[4] single_women_full_time_index_array
#cdef int[4] single_women_part_time_index_array
# cdef int[6] single_women_welfare_index_array
#cdef int[4] single_women_unemployed_index_array
#cdef int max_school  # 30 - 17
# cdef int max_1970
cdef int NO_KIDS
cdef double beta0  # discount rate
cdef double MINIMUM_UTILITY
cdef int[5] AGE_VALUES
cdef int[5] exp_vector
cdef double home_time_vector
cdef int ub_h   # UNEMPLOYMENT BENEFIT HUSBAND
cdef int ub_w   # UNEMPLOYMENT BENEFIT WIFE
# work status: (unemp, emp)
cdef int UNEMP
cdef int EMP
cdef int leisure
cdef int leisure_part
# ability wife/husband: (low, medium, high)) + match quality: (high, medium, low)
cdef double[3] normal_vector
cdef double[2] ability_vector
# marital status: (unmarried, married)
cdef int UNMARRIED
cdef int MARRIED
# school groups
cdef int school_size
cdef int exp_size
cdef int kids_size    # number of children: (0, 1, 2, 3+)
cdef int ability_size
cdef int home_time_size
cdef int mother_size
cdef int mother_marital_size
cdef int health_size
cdef int mother_educ
cdef int mother_marital
cdef int home_production
# maximum fertility age
cdef int MAX_FERTILITY_AGE
cdef double eta1    # fraction from parents net income  that one kid get
cdef double eta2    # fraction from parents net income that 2 kids get
cdef double eta3    # fraction from parents net  income that 3 kids get
cdef double eta4    # fraction from parents net income  that 4 kids get
cdef double scale   # fraction of public consumption
cdef double bp        # bargaining power
cdef int GRID
cdef int AGE     # initial age
cdef int GOOD    # health status
cdef int POOR
cdef int HK1     # 0 - 2 years of experience
cdef int HK2     # 3 - 5 years of experience
cdef int HK3     # 6 - 10 years of experience
cdef int HK4     # 11 + years of experience

cdef double mother_hispanic_newcommer      # probability mother was an immigrant

cdef double[3] mother

cdef int constant_welfare       # before 97
cdef int by_kids_welfare        # before 97
cdef double by_income_welfare   # before 97

cdef double cb_const         # child benefit for single mom + 1 kid - annually
cdef double cb_per_child
cdef int num_cohort
cdef double home_p
