import numpy as np
from time import perf_counter
cimport constant_parameters as c
from single_men cimport single_men
from single_women cimport single_women
from married_couple_emax cimport married_couple_emax


cpdef create_married_emax():
    return np.full([c.max_period, c.school_size, c.school_size, c.exp_size, c.exp_size, c.kids_size, c.health_size, c.health_size,
                       c.home_time_size, c.home_time_size, c.ability_size, c.ability_size, c.mother_size, c.mother_size, c.mother_size, c.mother_size],
                   float('-inf'))


cpdef create_single_w_emax():
    return np.full([c.max_period, c.school_size, c.exp_size, c.kids_size, c.health_size, c.home_time_size, c.ability_size, c.mother_size, c.mother_size],
                   float('-inf'))


cpdef create_single_h_emax():
    return np.full([c.max_period, c.school_size, c.exp_size, c.kids_size, c.health_size, c.home_time_size, c.ability_size, c.mother_size, c.mother_size],
                   float('-inf'))


def dump_married_emax(filename, emax):
    np.save(filename, emax)
    file = open(filename+".txt", "w+")
    print("dumping married emax matrix to: "+filename)
    for t in range(1, c.max_period):
        for s1 in range(0, c.school_size):
            for s2 in range(0, c.school_size):
                for e1 in range(0, c.exp_size):
                    for e2 in range(0, c.exp_size):
                        for k in range(0, c.kids_size):
                            for health1 in range(0, c.health_size):
                                for health2 in range(0, c.health_size):
                                    for home1 in range(0, c.home_time_size):
                                        for home2 in range(0, c.home_time_size):
                                            for ability1 in range(0, c.ability_size):
                                                for ability2 in range(0, c.ability_size):
                                                    for mother1 in range(0, c.mother_size):
                                                        for mother2 in range(0, c.mother_size):
                                                            for mother3 in range(0, c.mother_marital_size):
                                                                for mother4 in range(0, c.mother_marital_size):
                                                                    index = [t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                    str_index = ", ".join(str(i) for i in index)
                                                                    value = emax[t][s1][s2][e1][e2][k][health1][health2][home1][home2][ability1][ability2][mother1][mother2][mother3][mother4]
                                                                    file.write(str_index+", "+format(value, '.2f')+"\n")
    file.close()

def dump_single_emax(filename, emax):
    np.save(filename, emax)
    file = open(filename, "w+")
    print("dumping single emax matrix to: "+filename)
    for t in range(1, c.max_period):
        for s in range(0, c.school_size):
            for e in range(0, c.exp_size):
                for k in range(0, c.kids_size):
                    for health in range(0, c.health_size):
                        for home in range(0, c.home_time_size):
                            for ability in range(0, c.ability_size):
                                for mother1 in range(0, c.mother_size):
                                    for mother2 in range(0, c.mother_marital_size):
                                        index = [t, s, e, k, health, home, ability, mother1, mother2]
                                        str_index = ", ".join(str(i) for i in index)
                                        value = emax[t][s][e][k][health][home][ability][mother1][mother2]
                                        file.write(str_index+", "+format(value, '.2f')+"\n")
    file.close()

cpdef int calculate_emax(double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:,:,:,:] w_s_emax, double[:,:,:,:,:,:,:,:,:] h_s_emax, verbose) except -1:
    cdef int iter_count = 0
    cdef double tic
    cdef double toc
    # running until the one before last period
    for t in range(c.max_period - 1, 0, -1):
        # EMAX FOR SINGLE MEN
        tic = perf_counter()
        iter_count += single_men(t, w_emax, h_emax, w_s_emax, h_s_emax, verbose)
        # EMAX FOR SINGLE WOMEN
        iter_count += single_women(t, w_emax, h_emax, w_s_emax, h_s_emax, verbose)
        # EMAX FOR MARRIED COUPLE
        iter_count += married_couple_emax(t, w_emax, h_emax, w_s_emax, h_s_emax, verbose)
        toc = perf_counter()
        print("calculate emax for t=%d took: %.4f (sec)" % (t, (toc - tic)))

    return iter_count
