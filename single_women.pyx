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


cdef int single_women(int t, double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] h_emax,
    double[:,:,:,:,:,:,:,:,:] w_s_emax,
    double[:,:,:,:,:,:,:,:,:] h_s_emax, verbose) except -1:
    cdef double[3] mother
    cdef int iter_count = 0
    cdef double sum_emax
    cdef double weighted_utility = float('-inf')
    cdef int married_index = -99
    cdef int choose_partner = 0
    cdef int school
    cdef int exp
    cdef int kids
    cdef int home_time
    cdef int ability
    cdef int mother_educ
    cdef int mother_marital
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

    if verbose:
        print("====================== single women:  ======================")
    cdef draw_wife.Wife wife = draw_wife.Wife()
    wife.age = 17 + t
    # c.max_period, c.school_size, c.exp_size, c.kids_size, c.health_size, c.home_time_size, c.ability_size, c.mother_size, c.mother_size])
    for school in range(0, c.school_size):   # loop over school
        wife.schooling = school
        draw_wife.update_wife_schooling(wife)
        for exp in range(0, c.exp_size):           # loop over experience
            wife.exp = c.exp_vector[exp]
            wife.exp_2 = cmath.pow(wife.exp, 2)
            for kids in range(0, 4):                # for each number of kids: 0, 1, 2,  - open loop of kids
                wife.kids = kids
                for home_time in range(0, c.home_time_size):       # home time loop - three options
                    wife.home_time_ar = c.home_time_vector        #c.home_time_vector[home_time]
                    for ability in range(0, 1): #c.ability_size):     # for each ability level: low, medium, high - open loop of ability
                        wife.ability_i = ability
                        wife.ability_value = c.ability_vector[ability] * p.sigma_ability_w  # wife ability - low, medium, high
                        for mother_educ in range(0,c.mother_size):
                            wife.mother_educ = mother_educ
                            for mother_marital in range(0, c.mother_marital_size):
                                wife.mother_marital = mother_marital
                                draw_wife.update_ability_back(wife)
                                sum_emax = 0
                                iter_count = iter_count + 1
                                if verbose:
                                    print(wife)
                                for draw in range(0, c.DRAW_B):
                                    married_index = -99
                                    choose_partner = 0
                                    _, _, prob_full_w, prob_part_w, tmp_full_w = calculate_wage.calculate_wage_w(wife)
                                    calculate_utility_single_women(w_s_emax, 0, 0, tmp_full_w, wife, t, u_w_single_full, 1)

                                    #if wife.age < 20:
                                    #    prob_meet_potential_partner = cmath.exp(p.omega1) / (1.0 + cmath.exp(p.omega1))
                                    #else:
                                    #    temp = p.omega3 + p.omega4_w * wife.age + p.omega5_w * wife.age * wife.age
                                    #    prob_meet_potential_partner = cmath.exp(temp) / (1.0 + cmath.exp(temp))

                                    prob_meet_potential_partner = meeting_partner.prob(wife.age)
                                    assert prob_meet_potential_partner >= 0 and prob_meet_potential_partner <= 1, "invalid prob: " + str(prob_meet_potential_partner)

                                    husband = draw_husband.draw_husband_back(wife, c.mother[0], c.mother[1], c.mother[2])
                                    _, _, prob_full_h, prob_part_h, tmp_full_h = calculate_wage.calculate_wage_h(husband)
                                    calculate_utility_married(w_emax, h_emax, 0, 0, 0, 0, tmp_full_h, tmp_full_w, wife, husband, t,
                                            u_wife, u_husband, u_wife_full, u_husband_full, 1)
                                    calculate_utility_single_men(h_s_emax, 0, 0, tmp_full_h, husband, t, u_h_single_full, 1)
                                    #if prob_meet_potential_partner < 0.05:
                                    #    prob_meet_potential_partner =0.05
                                    if kids == 0:  # can't choose welfare
                                        expected_utility_single = prob_full_w * maxvalue_filter(u_w_single_full, [0,1,2,3, 6], 5) + \
                                                                  prob_part_w * maxvalue_filter(u_w_single_full, [0,1,4,5, 6], 5) + \
                                                                  (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_w_single_full, [0,1, 6], 3)
                                    else:  # have children so can choose to take welfare
                                        expected_utility_single = prob_full_w * maxvalue_filter(u_w_single_full, [0,1, 2,3, 6,7,8, 9, 10], 9) + \
                                                                  prob_part_w * maxvalue_filter(u_w_single_full, [0,1, 4,5, 6,7,8,11,12], 9) + \
                                                                  (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_w_single_full, [0,1, 6,7,8], 5)

                                    temp = prob_meet_potential_partner * (
                                        prob_full_h * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 2, 3, 6, 7, 8, 9], 8) +
                                        prob_full_h * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 2, 3, 12, 13, 14, 15], 8) +
                                        prob_full_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1, 2, 3], 4) +
                                        prob_part_h * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 4, 5, 10, 11, 6, 7], 8) +
                                        prob_part_h * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 4, 5, 16, 17, 12, 13], 8) +
                                        prob_part_h * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1, 4, 5], 4) +
                                        (1 - prob_full_h - prob_part_h) * prob_full_w * maxvalue_filter(u_wife_full, [0, 1, 6, 7], 4) +
                                        (1 - prob_full_h - prob_part_h) * prob_part_w * maxvalue_filter(u_wife_full, [0, 1, 12, 13],4) +
                                        (1 - prob_full_h - prob_part_h) * (1 - prob_full_w - prob_part_w) * maxvalue_filter(u_wife_full, [0, 1], 2)) + \
                                        (1 - prob_meet_potential_partner) * expected_utility_single


                                    sum_emax += temp
                                # end draw backward loop

                                w_s_emax[t][school][exp][kids][wife.health][home_time][ability][mother_educ][mother_marital] = sum_emax / c.DRAW_B

    return iter_count
