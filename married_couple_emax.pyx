import numpy as np
from parameters import p
cimport constant_parameters as c
cimport draw_husband
cimport draw_wife
cimport calculate_wage
cimport libc.math as cmath
cdef extern from "randn.cc":
    double uniform()
    double maxvalue_filter(double arr[], int indexes[], int ilen)
from calculate_utility_single_women cimport calculate_utility_single_women
from calculate_utility_married cimport calculate_utility_married
from calculate_utility_single_men cimport calculate_utility_single_men

cpdef int married_couple_emax(int t, double[:, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:] w_s_emax,
    double[:,:,:,:] h_s_emax, verbose) except -1:
    cdef int iter_count = 0
    cdef double w_sum = 0
    cdef double h_sum = 0
    cdef int married_index = -99
    cdef int choose_partner = 0
    cdef int school_w = 0
    cdef int school_h = 0
    cdef int kids = 0
    cdef int ability_w
    cdef int ability_h
    cdef int kb5
    cdef int we
    cdef int he
    cdef int mq
    cdef int draw
    cdef double wage_w_full
    cdef double wage_w_part
    cdef double wage_h_full
    cdef double wage_h_part
    cdef double single_women_value
    cdef double single_men_value
    cdef double weighted_utility
    cdef double husband_single_outside
    cdef double wife_single_outside
    cdef double[18] u_wife
    cdef double[18] u_husband
    cdef double[18] u_wife_full
    cdef double[18] u_husband_full
    cdef double[6] u_w_single_full
    cdef double[6] u_h_single_full
    cdef draw_wife.Wife wife = draw_wife.Wife()
    cdef draw_husband.Husband husband = draw_husband.Husband()
    if verbose:
        print("====================== married couple:  ======================")


    wife.age = 17 + t
    husband.age = wife.age
    for school_w in range(0, c.school_size):   # loop over school
        if 17 + t < c.AGE_VALUES[school_w]:   # wife's education level hasn't started yet
            continue
        wife.schooling = school_w
        draw_wife.update_wife_schooling(wife)
        for school_h in range(0, c.school_size):
            if 17 + t < c.AGE_VALUES[school_h]:   # husband's education level hasn't started yet
                continue
            husband.schooling = school_h
            draw_husband.update_school(husband)
            for kids in range(0, 4):                # for each number of kids: 0, 1, 2,  - open loop of kids
                wife.kids = kids
                for ability_w in range(0, c.ability_size):     # for each ability level: low, medium, high - open loop of ability
                    wife.ability_i = ability_w
                    wife.ability_value = c.ability_vector[ability_w] * p.sigma_ability_w
                    for ability_h in range(0, c.ability_size):
                        husband.ability_i = ability_h
                        husband.ability_value = c.ability_vector[ability_h] * p.sigma_ability_h
                        for kb5 in range(0, c.kids_below_5_size):
                            wife.kb5 = kb5
                            if kb5>kids:
                                continue
                            for we in range(0, c.emp_size):
                                wife.emp = we
                                wife.capacity = we
                                for he in range(0, c.emp_size):
                                    husband.emp = he
                                    husband.capacity = he
                                    for mq in range(0, c.match_quality_size):
                                        wife.match_quality = c.match_vector[mq]
                                        wife.match_quality_i = mq
                                        iter_count = iter_count + 1
                                        if verbose:
                                            print(wife)
                                            print(husband)

                                        # Wages and single values: independent of (temp, temp_preg, preg_possible).
                                        _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband, t)
                                        _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife, t)
                                        single_men_value, _ = calculate_utility_single_men(
                                            h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)
                                        # husband_single_outside depends only on husband state.
                                        husband_single_outside = prob_full_h * maxvalue_filter(u_h_single_full, [0, 2], 2) + \
                                                                 prob_part_h * maxvalue_filter(u_h_single_full, [0, 4], 2) + \
                                                                 (1 - prob_full_h - prob_part_h) * u_h_single_full[0]

                                        # Determine if biological pregnancy enumeration is needed.
                                        if wife.age >= c.MAX_FERTILITY_AGE or kids == 3:
                                            preg_pr = 0.0  # hard cap: only "not possible" branch matters
                                        else:
                                            preg_pr = c.preg_prob[wife.age - 18]

                                        # Quadrature over the continuous shocks (temp ~ N(0, sigma_q),
                                        # temp_preg ~ N(0, sigma_p)) and exact enumeration over the
                                        # biological pregnancy Bernoulli.
                                        w_sum = 0.0
                                        h_sum = 0.0
                                        for i_q in range(c.N_GH):
                                            temp = c.gh_nodes[i_q] * p.sigma_q
                                            w_q = c.gh_weights[i_q]
                                            for i_p in range(c.N_GH_PREG):
                                                temp_preg = c.gh_nodes_preg[i_p] * p.sigma_p
                                                w_p = c.gh_weights_preg[i_p]
                                                for biological in range(2):
                                                    if preg_pr == 0.0 and biological == 1:
                                                        continue  # hard cap: skip the impossible branch
                                                    if biological == 1:
                                                        w_bio = preg_pr
                                                    else:
                                                        w_bio = 1.0 - preg_pr
                                                    weight = w_q * w_p * w_bio
                                                    if weight == 0.0:
                                                        continue

                                                    calculate_utility_married(w_emax, h_emax, 0, 0, 0, 0, tmp_full_h, tmp_full_w, wife, husband, t,
                                                            u_wife, u_husband, u_wife_full, u_husband_full, 1,
                                                            temp, temp_preg, biological)
                                                    single_women_value, _ = calculate_utility_single_women(
                                                        w_s_emax, 0, 0, tmp_full_w, wife, t, u_w_single_full, 1,
                                                        temp_preg, biological)
                                                    wife_single_outside = prob_full_w * maxvalue_filter(u_w_single_full, [0, 1, 2, 3], 4) + \
                                                                          prob_part_w * maxvalue_filter(u_w_single_full, [0, 1, 4, 5], 4) + \
                                                                          (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_w_single_full, [0, 1], 2)

                                                    # bilateral comparison
                                                    weighted_utility = float('-inf')
                                                    married_index = -99
                                                    for i in range(0, 18):
                                                        if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                                                            if c.bp * u_wife[i] + (1 - c.bp) * u_husband[i] > weighted_utility:
                                                                weighted_utility = c.bp * u_wife[i] + (1 - c.bp) * u_husband[i]
                                                                married_index = i

                                                    if married_index > -99:
                                                        w_sum += weight * u_wife[married_index]
                                                        h_sum += weight * u_husband[married_index]
                                                    else:
                                                        w_sum += weight * wife_single_outside
                                                        h_sum += weight * husband_single_outside

                                        w_emax[t][school_w][school_h][kids][ability_w][ability_h][kb5][we][he][mq] = w_sum
                                        h_emax[t][school_w][school_h][kids][ability_w][ability_h][kb5][we][he][mq] = h_sum

    return iter_count
