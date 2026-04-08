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
    double[:,:,:,:,:] h_s_emax, verbose) except -1:
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
    cdef double[13] u_w_single_full
    cdef double[7] u_h_single_full

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
        for kids in range(0, 2):                # for each number of kids: 0, 1,   - open loop of kids
            husband.kids = kids
            for ability in range(0, c.ability_size):     # for each ability level: low, medium, high - open loop of ability
                husband.ability_i = ability
                husband.ability_value = c.ability_vector[ability] * p.sigma_ability_h
                for he in range(0, c.emp_size):
                    sum_emax = 0
                    iter_count = iter_count + 1
                    if verbose:
                        print(husband)
                    for draw in range(0, c.DRAW_B):
                        married_index = -99
                        choose_partner = 0
                        _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband, t)
                        single_men_value, _ = calculate_utility_single_men(
                            h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)

                        prob_meet_potential_partner = meeting_partner.prob(husband.age)

                        wife = draw_wife.draw_wife_back(husband)
                        _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife, t)
                        calculate_utility_married(w_emax, h_emax, 0, 0, 0, 0, tmp_full_h, tmp_full_w, wife, husband, t,
                                u_wife, u_husband, u_wife_full, u_husband_full, 1)
                        single_women_value, _ = calculate_utility_single_women(
                            w_s_emax, 0, 0, tmp_full_w, wife, t, u_w_single_full, 1)

                        # bilateral comparison - find best married option where both prefer marriage
                        weighted_utility = float('-inf')
                        married_index = -99
                        for i in range(0, 18):
                            if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                                if c.bp * u_wife[i] + (1 - c.bp) * u_husband[i] > weighted_utility:
                                    weighted_utility = c.bp * u_wife[i] + (1 - c.bp) * u_husband[i]
                                    married_index = i

                        # calculate single outside option
                        single_outside_option = prob_full_h * maxvalue_filter(u_h_single_full, [0, 2, 6], 3) + \
                                                prob_part_h * maxvalue_filter(u_h_single_full, [0, 4, 6], 3) + \
                                                (1 - prob_full_h - prob_part_h) * maxvalue_filter(u_h_single_full, [0, 6], 2)

                        if married_index > -99:
                            temp = prob_meet_potential_partner * u_husband[married_index] + (1 - prob_meet_potential_partner) * single_outside_option
                        else:
                            temp = single_outside_option
                        sum_emax += temp

                    # end draw backward loop
                    h_s_emax[t][school][kids][ability][he] = sum_emax / c.DRAW_B
                    if verbose:
                        print("emax(", t, ", ", school, ", ", kids, ",", ability, ",", he, ")=", sum_emax / c.DRAW_B)
                        print("======================================================")

    return iter_count
