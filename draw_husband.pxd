from draw_wife cimport Wife

# Husband class
cdef class Husband:
    cdef int hsd
    cdef int hsg
    cdef int sc
    cdef int cg
    cdef int pc
    cdef int schooling            # husband schooling, can get values of 0-4
    cdef int years_of_schooling
    cdef double exp                  # husband experience
    cdef double exp_2                 # husband experience
    cdef int emp
    cdef double capacity
    cdef double divorce
    cdef int married
    cdef int age
    cdef int kids                 # always zero unless single. if married - all kids at women structure
    cdef int health
    cdef double home_time_ar
    cdef double ability_value
    cdef int ability_i
    cdef int mother_educ
    cdef int mother_marital
    cdef int mother_immig

# draw a husband
cpdef Husband draw_husband(Wife wife, double mother0, double mother1, double mother2)
cpdef Husband draw_husband_back(Wife wife, double mother0, double mother1, double mother2)
cpdef update_school(Husband husband)        # this function update education in Husnabds structures
cpdef update_mother_char(Husband husband, double mother0, double mother1, double mother2)
cpdef update_ability_forward(Husband husband)
cpdef update_ability_back(Husband husband)
