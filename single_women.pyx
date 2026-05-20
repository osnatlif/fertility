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


cdef int single_women(int t, double[:, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:] w_s_emax,
    double[:,:,:,:] h_s_emax, verbose) except -1:
    cdef int iter_count = 0
    cdef double sum_emax
    cdef double weighted_utility = float('-inf')
    cdef int married_index = -99
    cdef int choose_partner = 0
    cdef int school
    cdef int kids
    cdef int ability
    cdef int kb5
    cdef int we
    cdef int draw
    cdef double wage_w_full
    cdef double wage_w_part
    cdef double wage_h_full
    cdef double wage_h_part
    cdef double single_women_value
    cdef double single_men_value
    cdef double single_outside_option
    cdef double[18] u_wife
    cdef double[18] u_husband
    cdef double[18] u_wife_full
    cdef double[18] u_husband_full
    cdef double[13] u_w_single_full
    cdef double[7] u_h_single_full

    if verbose:
        print("====================== single women:  ======================")
    cdef draw_wife.Wife wife = draw_wife.Wife()
    cdef draw_husband.Husband husband
    wife.age = 17 + t
    for school in range(0, c.school_size):   # loop over school
        if 17 + t < c.AGE_VALUES[school]:   # education level hasn't started yet at this age
            continue
        wife.schooling = school
        draw_wife.update_wife_schooling(wife)
        for kids in range(0, 4):                # for each number of kids: 0, 1, 2,  - open loop of kids
            wife.kids = kids
            for ability in range(0, c.ability_size):     # for each ability level: low, medium, high - open loop of ability
                wife.ability_i = ability
                wife.ability_value = c.ability_vector[ability] * p.sigma_ability_w  # wife ability - low, medium, high
                for kb5 in range(0, c.kids_below_5_size):
                    if kb5 > kids:
                        continue
                    wife.kb5 = kb5
                    for we in range(0, c.emp_size):
                        wife.emp = we
                        wife.capacity = we
                        sum_emax = 0
                        iter_count = iter_count + 1
                        if verbose:
                            print(wife)

                        # Things that depend only on the wife's state.
                        _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife, t)
                        prob_meet_potential_partner = meeting_partner.prob(wife.age)

                        # biological pregnancy enumeration is conditional on hard cap
                        if wife.age >= c.MAX_FERTILITY_AGE or kids == 3:
                            preg_pr = 0.0
                        else:
                            preg_pr = c.preg_prob[wife.age - 18]

                        # Build husband object (state to be set inside enumeration).
                        p_hs, p_sc, p_cg = draw_husband.husband_school_probs(wife.age)
                        p_low, p_med, p_high = draw_husband.ability_probs()
                        husband = draw_husband.Husband()
                        husband.age = wife.age
                        if husband.age > 24:
                            husband.emp = 1
                            husband.capacity = 1
                        else:
                            husband.emp = 0
                            husband.capacity = 0

                        for husband_school in range(0, c.school_size):
                            if husband_school == 0:
                                prob_s = p_hs
                            elif husband_school == 1:
                                prob_s = p_sc
                            else:
                                prob_s = p_cg
                            husband.schooling = husband_school
                            draw_husband.update_school(husband)
                            for husband_ability in range(0, c.ability_size):
                                if husband_ability == 0:
                                    prob_a = p_low
                                elif husband_ability == 1:
                                    prob_a = p_med
                                else:
                                    prob_a = p_high
                                husband.ability_i = husband_ability
                                husband.ability_value = c.ability_vector[husband_ability] * p.sigma_ability_h

                                # husband wage and single_men_value: not a function of (temp_preg, biological)
                                _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband, t)
                                single_men_value, _ = calculate_utility_single_men(
                                    h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)

                                # Quadrature over temp_preg (continuous) and biological pregnancy (Bernoulli).
                                # temp (match-quality residual) is 0 here -- new marriage.
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
                                        single_outside_option = prob_full_w * maxvalue_filter(u_w_single_full, [0, 1, 2, 3], 4) + \
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
                                            value = prob_meet_potential_partner * u_wife[married_index] + (1 - prob_meet_potential_partner) * single_outside_option
                                        else:
                                            value = single_outside_option
                                        sum_emax += prob_s * prob_a * weight * value

                        w_s_emax[t][school][kids][ability][kb5][we] = sum_emax

    return iter_count
