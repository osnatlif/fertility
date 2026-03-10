import timeit
import numpy as np
import math
import random
from libc.math cimport exp as cexp
from libc.math cimport log as clog
from libc.math cimport pow as cpow
from scipy.stats import norm
cdef extern from "randn.c":
    double randn(double mu, double sigma)
    double uniform()
    double maxvalue_filter(double arr[], int indexes[], int ilen)


cpdef test():
    arr_size = 100000
    arr = np.random.random(arr_size)

    print("exp results")
    start_time = timeit.default_timer()
    [np.exp(v) for v in arr]
    print("numpy results (usec):", 1000000*(timeit.default_timer() - start_time)/arr_size)

    start_time = timeit.default_timer()
    [math.exp(v) for v in arr]
    print("math results (usec):", 1000000*(timeit.default_timer() - start_time)/arr_size)

    start_time = timeit.default_timer()
    [cexp(v) for v in arr]
    print("c results (usec):", 1000000*(timeit.default_timer() - start_time)/arr_size)

    print("log results")
    start_time = timeit.default_timer()
    [np.log(v) for v in arr]
    print("numpy results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    [math.log(v) for v in arr]
    print("math results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    [clog(v) for v in arr]
    print("c results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    print("pow results")
    start_time = timeit.default_timer()
    [v**2 for v in arr]
    print("operator results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    [np.power(v, 2) for v in arr]
    print("numpy results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    [math.pow(v, 2) for v in arr]
    print("math results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    [cpow(v, 2) for v in arr]
    print("c results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    print("normal random results")
    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = norm.rvs(0, 1)
    print("scipy results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = np.random.normal(0, 1)
    print("numpy results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = random.gauss(0, 1)
    print("random results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = randn(0, 1)
    print("randn results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    print("uniform random results")
    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = np.random.uniform(0, 1)
    print("numpy results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = random.uniform(0, 1)
    print("uniform results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    start_time = timeit.default_timer()
    for i in range(1, arr_size):
        v = uniform()
    print("c uniform results (usec):", 1000000 * (timeit.default_timer() - start_time) / arr_size)

    cdef double[7] values = [10, 17, 99, 100, 1, 2, -100]
    cdef int[4] indexes = [0, 4, 5, 6]
    print("max value of: ", values)
    print("among indexs: ", indexes)
    print("is: ", maxvalue_filter(values, indexes, 4))