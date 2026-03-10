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

cpdef int married_couple_emax(int t, double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:,:,:,:] w_s_emax,
    double[:,:,:,:,:,:,:,:,:] h_s_emax, verbose) except -1:
    cdef double[3] mother
    cdef int iter_count = 0
    cdef double w_sum = 0
    cdef double h_sum = 0
    cdef int married_index = -99
    cdef int choose_partner = 0
    cdef int school_w = 0
    cdef int school_h = 0
    cdef int exp_w = 0
    cdef int exp_h = 0
    cdef int kids = 0
    cdef int home_time_w
    cdef int home_time_h
    cdef int ability_w
    cdef int ability_h
    cdef int mother_educ_w
    cdef int mother_educ_h
    cdef int mother_marital_w
    cdef int mother_marital_h
    cdef int draw
    cdef double wage_w_full
    cdef double wage_w_part
    cdef double wage_h_full
    cdef double wage_h_part
    cdef double single_women_value
    cdef double single_men_value
    cdef double[18] u_wife
    cdef double[18] u_husband
    cdef double[18] u_wife_full
    cdef double[18] u_husband_full
    cdef double[13] u_w_single_full
    cdef double[7] u_h_single_full
    cdef draw_wife.Wife wife = draw_wife.Wife()
    cdef draw_husband.Husband husband = draw_husband.Husband()
    cdef double temp
    if verbose:
        print("====================== married couple:  ======================")


    wife.age = 17 + t
    husband.age = wife.age
    for school_w in range(0, c.school_size):   # loop over school
        wife.schooling = school_w
        draw_wife.update_wife_schooling(wife)
        for school_h in range(0, c.school_size):
            husband.schooling = school_h
            draw_husband.update_school(husband)
            for exp_w in range(0, c.exp_size):           # loop over experience
                wife.exp = c.exp_vector[exp_w]
                wife.exp_2 = cmath.pow(wife.exp, 2)
                for exp_h in range(0, c.exp_size):
                    husband.exp = c.exp_vector[exp_h]
                    for kids in range(0, 4):                # for each number of kids: 0, 1, 2,  - open loop of kids
                        wife.kids = kids
                        for home_time_w in range(0,c.home_time_size):       # range(0, 3):       # home time loop - three options
                            wife.home_time_ar = c.home_time_vector          #c.home_time_vector[home_time_w]
                            for home_time_h in range(0,c.home_time_size):   # range(0, 3):
                                husband.home_time_ar = c.home_time_vector   #c.home_time_vector[home_time_h]
                                for ability_w in range(0, 1):#c.ability_size):     # for each ability level: low, medium, high - open loop of ability
                                    #wife.ability_i = ability_w
                                    #wife.ability_value = c.ability_vector[ability_w] * p.sigma_ability_w  # wife ability - low, medium, high
                                    for ability_h in range(0, 1): #c.ability_size):
                                        #husband.ability_i = ability_h
                                        #husband.ability_value = c.ability_vector[ability_h] * p.sigma_ability_h  # wife ability - low, medium, high
                                        for mother_educ_w in range(0, c.mother_size): #range(0, 2)
                                            wife.mother_educ = mother_educ_w
                                            for mother_educ_h in range(0, c.mother_size): #range(0, 2)
                                                husband.mother_educ = mother_educ_h
                                                for mother_marital_w in range(0, c.mother_marital_size): #range(0, 2)
                                                    wife.mother_marital = mother_marital_w
                                                    for mother_marital_h in range(0, c.mother_marital_size): #range(0, 2)
                                                        husband.mother_marital = mother_marital_h
                                                        draw_wife.update_ability_back(wife)
                                                        draw_husband.update_ability_back(husband)
                                                        w_sum = 0
                                                        h_sum = 0
                                                        iter_count = iter_count + 1
                                                        if verbose:
                                                            print(wife)
                                                            print(husband)

                                                        for draw in range(0, c.DRAW_B):
                                                            married_index = -99
                                                            _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife)
                                                            _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband)
                                                            calculate_utility_single_women(w_s_emax, 0, 0, tmp_full_w, wife, t, u_w_single_full, 1)
                                                            calculate_utility_single_men(h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)
                                                            calculate_utility_married(w_emax, h_emax, 0, 0, 0, 0, tmp_full_h, tmp_full_w, wife, husband, t, 
                                                                    u_wife, u_husband, u_wife_full, u_husband_full, 1)
                                                            #weighted_utility = float('-inf')
                                                            #married_index = -99
                                                            #for i in range(0, 18):
                                                            #    if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                                                            #        if c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i] > weighted_utility:
                                                            #            weighted_utility = c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i]
                                                            #            married_index = i
                                                            if wife.age < 20:
                                                                prob_meet_potential_partner = cmath.exp(p.omega1) / (
                                                                        1.0 + cmath.exp(p.omega1))
                                                            else:
                                                                temp = p.omega3 + p.omega4_w * wife.age + p.omega5_w * wife.age * wife.age
                                                                prob_meet_potential_partner = cmath.exp(temp) / (
                                                                        1.0 + cmath.exp(temp))
                                                            if kids == 0:  # can't choose welfare
                                                                expected_utility_single = prob_full_w * maxvalue_filter(u_w_single_full, [0, 1, 2, 3, 6], 5) + \
                                                                                          prob_part_w * maxvalue_filter(u_w_single_full, [0, 1, 4, 5, 6], 5) + \
                                                                                          (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_w_single_full, [0, 1, 6], 3)
                                                            else:  # have children so can choose to take welfare
                                                                expected_utility_single = prob_full_w * maxvalue_filter(u_w_single_full, [0, 1, 2, 3, 6, 7, 8, 9, 10], 9) + \
                                                                                          prob_part_w * maxvalue_filter(u_w_single_full, [0, 1, 4, 5, 6, 7, 8, 11, 12], 9) + \
                                                                                          (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_w_single_full, [0, 1, 6, 7, 8], 5)

                                                            prob_not_divorce = 0.9

                                                            temp_h = prob_not_divorce * (
                                                                prob_full_h * prob_full_w * maxvalue_filter(u_husband_full, [0, 1, 2, 3, 6, 7, 8, 9], 8) +
                                                                prob_full_h * prob_part_w * maxvalue_filter(u_husband_full, [0, 1, 2, 3, 12, 13, 14, 15], 8) +
                                                                prob_full_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_husband_full, [0, 1, 2, 3], 4) +
                                                                prob_part_h * prob_full_w * maxvalue_filter(u_husband_full, [0, 1, 4, 5, 10, 11, 6, 7], 8) +
                                                                prob_part_h * prob_part_w * maxvalue_filter(u_husband_full, [0, 1, 4, 5, 16, 17, 12, 13], 8) +
                                                                prob_part_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_husband_full, [0, 1, 4, 5], 4) +
                                                                (1 - prob_full_h - prob_part_h) * prob_full_w * maxvalue_filter(u_husband_full, [0, 1, 6, 7], 4) +
                                                                (1 - prob_full_h - prob_part_h) * prob_part_w * maxvalue_filter(u_husband_full, [0, 1, 12, 13], 4) +
                                                                (1 - prob_full_h - prob_part_h) * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_husband_full, [0, 1], 2)) + \
                                                                (1 - prob_not_divorce) * (
                                                                    prob_full_h * maxvalue_filter(u_h_single_full, [0, 2, 6], 3) +
                                                                    prob_part_h * maxvalue_filter(u_h_single_full, [0, 4, 6], 3) +
                                                                    (1 - prob_full_h - prob_part_h) * maxvalue_filter(u_h_single_full, [0,  6], 2))

                                                            temp_w = prob_not_divorce * (
                                                                prob_full_h * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 2, 3,6, 7, 8, 9], 8) +
                                                                prob_full_h * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 2, 3, 12, 13, 14, 15], 8) +
                                                                prob_full_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1, 2, 3], 4) +
                                                                prob_part_h * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 4, 5, 10, 11, 6,7], 8) +
                                                                prob_part_h * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 4, 5,16, 17, 12,13], 8) +
                                                                prob_part_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1, 4, 5], 4) +
                                                                (1 - prob_full_h - prob_part_h) * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 6, 7], 4) +
                                                                (1 - prob_full_h - prob_part_h) * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 12, 13], 4) +
                                                                (1 - prob_full_h - prob_part_h) * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1], 2)) + \
                                                                (1 - prob_not_divorce) * expected_utility_single

                                                            h_sum += temp_h
                                                            w_sum += temp_w

                                                        # end draw backward loop
                                                        w_emax[t][school_w][school_h][exp_w][exp_h][kids][c.GOOD][c.GOOD][home_time_w][home_time_h][ability_w] \
                                                            [ability_h][mother_educ_w][mother_educ_h][mother_marital_w][mother_marital_h] = w_sum / c.DRAW_B
                                                        h_emax[t][school_w][school_h][exp_w][exp_h][kids][c.GOOD][c.GOOD][home_time_w][home_time_h][ability_w] \
                                                            [ability_h][mother_educ_w][mother_educ_h][mother_marital_w][mother_marital_h] = h_sum / c.DRAW_B

    return iter_count
