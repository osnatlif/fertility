from draw_husband cimport Husband

# Wife class
cdef class Wife:
    cdef int hsd
    cdef int hsg
    cdef int sc
    cdef int cg
    cdef int pc
    cdef int schooling              # wife schooling, can get values of 0-4
    cdef int years_of_schooling
    cdef double exp                 # wife experience
    cdef double exp_2               # wife experience squared
    cdef int emp                    # wife employment state
    cdef double capacity
    cdef int married
    cdef int divorce
    cdef int age
    cdef int kids                       # wife's kids
    cdef int health
    cdef int preg
    cdef double home_time_ar
    cdef double ability_value
    cdef int ability_i
    cdef int mother_educ
    cdef int mother_marital
    cdef int mother_immig
    cdef int on_welfare
    cdef int welfare_periods
    cdef int age_first_child
    cdef int age_second_child
    cdef int age_third_child
    cdef double match_quality
cpdef update_wife_schooling(Wife wife)

# update wife's ability
#cpdef update_ability(int ability, Wife wife)
cpdef Wife draw_wife(Husband husband, double mother1, double mother2, double mother3)
cpdef Wife draw_wife_back(Husband husband, double mother1, double mother2, double mother3)
cpdef update_mother_char(Wife wife, double mother1, double mother2, double mother3)
cpdef update_ability_forward(Wife wife)
cpdef update_ability_back(Wife wife)
