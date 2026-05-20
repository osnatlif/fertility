import numpy as np
from parameters import p
cimport constant_parameters as c
cimport draw_husband
cimport draw_wife
cimport calculate_wage
cimport meeting_partner
cimport libc.math as cmath
cdef extern from "randn.cc":
    double uniform()
    double maxvalue_filter(double arr[], int indexes[], int ilen)
from calculate_utility_single_women cimport calculate_utility_single_women
from calculate_utility_married cimport calculate_utility_married
from calculate_utility_single_men cimport calculate_utility_single_men


cdef int single_men(int t, double[:, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:] w_s_emax,
    double[:,:,:,:] h_s_emax, verbose) except -1:
    cdef int iter_count = 0
    cdef double sum_emax = 0
    cdef int married_index = -99
    cdef int choose_partner = 0
    cdef int school
    cdef int kids
    cdef int ability
    cdef int he
    cdef int draw
    cdef double wage_w_full
    cdef double wage_w_part
    cdef double wage_h_full
    cdef double wage_h_part
    cdef double single_women_value
    cdef double single_men_value
    cdef double weighted_utility
    cdef double single_outside_option
    cdef double[18] u_wife
    cdef double[18] u_husband
    cdef double[18] u_wife_full
    cdef double[18] u_husband_full
    cdef double[6] u_w_single_full
    cdef double[6] u_h_single_full

    if verbose:
        print("====================== single men:  ======================")
    cdef draw_husband.Husband husband = draw_husband.Husband()
    cdef draw_wife.Wife wife = draw_wife.Wife()
    husband.age = 17 + t
    for school in range(0, c.school_size):   # loop over school
        if 17 + t < c.AGE_VALUES[school]:   # education level hasn't started yet at this age
            continue
        husband.schooling = school
        draw_husband.update_school(husband)
        for ability in range(0, c.ability_size):     # for each ability level: low, medium, high - open loop of ability
            husband.ability_i = ability
            husband.ability_value = c.ability_vector[ability] * p.sigma_ability_h
            for he in range(0, c.emp_size):
                    husband.emp = he
                    husband.capacity = he
                    sum_emax = 0
                    iter_count = iter_count + 1
                    if verbose:
                        print(husband)

                    # Things that don't depend on the drawn wife: compute once.
                    _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband, t)
                    single_men_value, _ = calculate_utility_single_men(
                        h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)
                    prob_meet_potential_partner = meeting_partner.prob(husband.age)
                    single_outside_option = prob_full_h * maxvalue_filter(u_h_single_full, [0, 2], 2) + \
                                            prob_part_h * maxvalue_filter(u_h_single_full, [0, 4], 2) + \
                                            (1 - prob_full_h - prob_part_h) * u_h_single_full[0]

                    # Exact integration over the partner's discrete state:
                    # wife schooling (3 levels) x wife ability (3 levels) = 9 weighted points.
                    p_hs, p_sc, p_cg = draw_wife.wife_school_probs(husband.age)
                    p_low, p_med, p_high = draw_husband.ability_probs()
                    wife = draw_wife.Wife()
                    wife.age = husband.age
                    if wife.age > 24:
                        wife.emp = 1
                        wife.capacity = 1
                    else:
                        wife.emp = 0
                        wife.capacity = 0

                    # biological pregnancy enumeration is conditional on hard cap
                    if wife.age >= c.MAX_FERTILITY_AGE or wife.kids == 3:
                        preg_pr = 0.0
                    else:
                        preg_pr = c.preg_prob[wife.age - 18]

                    for wife_school in range(0, c.school_size):
                        if wife_school == 0:
                            prob_s = p_hs
                        elif wife_school == 1:
                            prob_s = p_sc
                        else:
                            prob_s = p_cg
                        wife.schooling = wife_school
                        draw_wife.update_wife_schooling(wife)
                        for wife_ability in range(0, c.ability_size):
                            if wife_ability == 0:
                                prob_a = p_low
                            elif wife_ability == 1:
                                prob_a = p_med
                            else:
                                prob_a = p_high
                            wife.ability_i = wife_ability
                            wife.ability_value = c.ability_vector[wife_ability] * p.sigma_ability_w

                            _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife, t)

                            # Quadrature over temp_preg (continuous) and biological pregnancy (Bernoulli).
                            # temp (match-quality residual) is 0 here because we're considering a NEW marriage.
                            for i_p in range(c.N_GH_PREG):
                                temp_preg = c.gh_nodes_preg[i_p] * p.sigma_p
                                w_p = c.gh_weights_preg[i_p]
                                for biological in range(2):
                                    if preg_pr == 0.0 and biological == 1:
                                        continue
                                    if biological == 1:
                                        w_bio = preg_pr
                                    else:
                                        w_bio = 1.0 - preg_pr
                                    weight = w_p * w_bio
                                    if weight == 0.0:
                                        continue

                                    calculate_utility_married(w_emax, h_emax, 0, 0, 0, 0, tmp_full_h, tmp_full_w, wife, husband, t,
                                            u_wife, u_husband, u_wife_full, u_husband_full, 1,
                                            0.0, temp_preg, biological)
                                    single_women_value, _ = calculate_utility_single_women(
                                        w_s_emax, 0, 0, tmp_full_w, wife, t, u_w_single_full, 1,
                                        temp_preg, biological)

                                    # bilateral comparison
                                    weighted_utility = float('-inf')
                                    married_index = -99
                                    for i in range(0, 18):
                                        if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                                            if c.bp * u_wife[i] + (1 - c.bp) * u_husband[i] > weighted_utility:
                                                weighted_utility = c.bp * u_wife[i] + (1 - c.bp) * u_husband[i]
                                                married_index = i

                                    if married_index > -99:
                                        value = prob_meet_potential_partner * u_husband[married_index] + (1 - prob_meet_potential_partner) * single_outside_option
                                    else:
                                        value = single_outside_option
                                    sum_emax += prob_s * prob_a * weight * value

                    h_s_emax[t][school][ability][he] = sum_emax
                    if verbose:
                        print("emax(", t, ", ", school, ", ",  ability, ",", he, ")=", sum_emax)
                        print("======================================================")

    return iter_count
