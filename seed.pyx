from libc.stdlib cimport srand

cpdef seed(s):
    srand(s)
