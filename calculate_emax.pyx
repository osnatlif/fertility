import numpy as np
from time import perf_counter
cimport constant_parameters as c
from single_men cimport single_men
from single_women cimport single_women
from married_couple_emax cimport married_couple_emax
from seed cimport seed


cpdef create_married_emax():
    # 11-D: [t, school_w, school_h, kids, ability_w, ability_h, kb5, wife_exp_idx, we, he, mq]
    return np.full([c.max_period, c.school_size, c.school_size, c.kids_size, c.ability_size, c.ability_size,
                    c.kids_below_5_size, c.N_EXP, c.emp_size, c.emp_size, c.match_quality_size],
                   float('-inf'))


cpdef create_single_w_emax():
    # 7-D: [t, school, kids, ability, kb5, wife_exp_idx, we]
    return np.full([c.max_period, c.school_size, c.kids_size, c.ability_size,
                    c.kids_below_5_size, c.N_EXP, c.emp_size],
                   float('-inf'))


cpdef create_single_h_emax():
    return np.full([c.max_period, c.school_size, c.ability_size,
                    c.emp_size],
                   float('-inf'))


def dump_married_emax(filename, emax):
    np.save(filename, emax)
    file = open(filename+".txt", "w+")
    print("dumping married emax matrix to: "+filename)
    for t in range(1, c.max_period):
        for s1 in range(0, c.school_size):
            for s2 in range(0, c.school_size):
                for k in range(0, c.kids_size):
                    for ability1 in range(0, c.ability_size):
                        for ability2 in range(0, c.ability_size):
                            for kb5 in range(0, c.kids_below_5_size):
                                for exp_idx in range(0, c.N_EXP):
                                    for we in range(0, c.emp_size):
                                        for he in range(0, c.emp_size):
                                            for mq in range(0, c.match_quality_size):
                                                index = [t, s1, s2, k, ability1, ability2, kb5, exp_idx, we, he, mq]
                                                str_index = ", ".join(str(i) for i in index)
                                                value = emax[t][s1][s2][k][ability1][ability2][kb5][exp_idx][we][he][mq]
                                                file.write(str_index+", "+format(value, '.2f')+"\n")
    file.close()

def dump_single_w_emax(filename, emax):
    np.save(filename, emax)
    file = open(filename, "w+")
    print("dumping single women emax matrix to: "+filename)
    for t in range(1, c.max_period):
        for s in range(0, c.school_size):
            for k in range(0, c.kids_size):
                for ability in range(0, c.ability_size):
                    for kb5 in range(0, c.kids_below_5_size):
                        for exp_idx in range(0, c.N_EXP):
                            for we in range(0, c.emp_size):
                                index = [t, s, k, ability, kb5, exp_idx, we]
                                str_index = ", ".join(str(i) for i in index)
                                value = emax[t][s][k][ability][kb5][exp_idx][we]
                                file.write(str_index+", "+format(value, '.2f')+"\n")
    file.close()

def dump_single_h_emax(filename, emax):
    np.save(filename, emax)
    file = open(filename, "w+")
    print("dumping single men emax matrix to: "+filename)
    for t in range(1, c.max_period):
        for s in range(0, c.school_size):
            for ability in range(0, c.ability_size):
                for he in range(0, c.emp_size):
                    index = [t, s, ability, he]
                    str_index = ", ".join(str(i) for i in index)
                    value = emax[t][s][ability][he]
                    file.write(str_index+", "+format(value, '.2f')+"\n")
    file.close()

cpdef int calculate_emax(double[:,:,:,:,:,:,:,:,:,:,:] w_emax,
    double[:,:,:,:,:,:,:,:,:,:,:] h_emax,
    double[:,:,:,:,:,:,:] w_s_emax, double[:,:,:,:] h_s_emax, verbose) except -1:
    cdef int iter_count = 0
    cdef double tic
    cdef double toc
    # reseed at start of each backward solve so that common random numbers
    # are used across parameter trials in an estimation loop
    seed(1)
    np.random.seed(1)
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
        if verbose:
            print("calculate emax for t=%d took: %.4f (sec)" % (t, (toc - tic)))

    return iter_count
