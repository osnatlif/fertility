from draw_husband cimport Husband

# Wife class
cdef class Wife:
    cdef int hs
    cdef int sc
    cdef int cg
    cdef public int schooling        # wife schooling, 0=HS, 1=SC, 2=CG+
    cdef int years_of_schooling
    cdef int emp                    # wife employment state
    cdef double capacity
    cdef int married
    cdef int divorce
    cdef int age
    cdef int kids                       # wife's kids
    cdef int preg
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
    cdef int kb5                       # number of kids below 5
    cdef double match_quality
cpdef update_wife_schooling(Wife wife)

# update wife's ability
#cpdef update_ability(int ability, Wife wife)
cpdef Wife draw_wife(Husband husband)
cpdef Wife draw_wife_back(Husband husband)
cpdef update_ability_forward(Wife wife)
cpdef update_ability_back(Wife wife)
