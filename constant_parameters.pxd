# number of draws
cdef int DRAW_B
cdef int cohort
cdef int max_period  # retirement

cdef int NO_KIDS
cdef double beta0  # discount rate
cdef double MINIMUM_UTILITY
cdef int[3] AGE_VALUES
cdef int ub_h   # UNEMPLOYMENT BENEFIT HUSBAND
cdef int ub_w   # UNEMPLOYMENT BENEFIT WIFE
# work status: (unemp, emp)
cdef int UNEMP
cdef int EMP
cdef double leisure
cdef double leisure_part
# ability wife/husband: (low, medium, high)) + match quality: (high, medium, low)
cdef double[3] normal_vector
cdef double[3] ability_vector
cdef double[3] match_vector
# marital status: (unmarried, married)
cdef int UNMARRIED
cdef int MARRIED
# school groups
cdef int school_size
cdef int kids_size    # number of children: (0, 1, 2, 3+)
cdef int kids_below_5_size  # number of children below 5: (0, 1, 2, 3)
cdef int ability_size
cdef int emp_size     # employed in previous period: (0=NO, 1=YES)
cdef int match_quality_size  # match quality: (LOW, MEDIUM, HIGH)
cdef int mother_size
cdef int mother_marital_size
cdef int mother_educ
cdef int mother_marital
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

cdef double mother_hispanic_newcommer      # probability mother was an immigrant

cdef double[3] mother

cdef int constant_welfare       # before 97
cdef int by_kids_welfare        # before 97
cdef double by_income_welfare   # before 97

cdef double cb_const         # child benefit for single mom + 1 kid - annually
cdef double cb_per_child
cdef int num_cohort
cdef double home_p
cdef double[39] preg_prob  # pregnancy probability by age, index 0=age18 to index 38=age56
cdef double childcare_cost  # annual childcare cost per child below 5
