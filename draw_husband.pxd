from draw_wife cimport Wife

# Husband class
cdef class Husband:
    cdef int hs
    cdef int sc
    cdef int cg
    cdef public int schooling      # husband schooling, 0=HS, 1=SC, 2=CG+
    cdef int years_of_schooling
    cdef int emp
    cdef double capacity
    cdef double divorce
    cdef int married
    cdef int age
    cdef int kids                 # always zero unless single. if married - all kids at women structure
    cdef double ability_value
    cdef int ability_i
    cdef int mother_educ
    cdef int mother_marital
    cdef int mother_immig

# draw a husband
cpdef Husband draw_husband(Wife wife)
cpdef Husband draw_husband_back(Wife wife)
cpdef update_school(Husband husband)        # this function update education in Husnabds structures
cpdef update_ability_forward(Husband husband)
cpdef update_ability_back(Husband husband)
cpdef tuple husband_school_probs(int age)
cpdef tuple ability_probs()
