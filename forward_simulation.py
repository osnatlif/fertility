import numpy as np
from parameters import p
import constant_parameters as c
import draw_husband
import draw_wife
import calculate_wage
import meeting_partner
from calculate_utility_married import calculate_utility_married
from calculate_utility_single_men import calculate_utility_single_men
from calculate_utility_single_women import calculate_utility_single_women
from update_wife_husband_objects import update_wife_single
from update_wife_husband_objects import update_husband_single
from update_wife_husband_objects import update_married
from moments import Moments, calculate_moments
from seed import seed


def forward_simulation(w_emax, h_emax, w_s_emax, h_s_emax, verbose, display_moments):
    seed(1)
    np.random.seed(1)
    m = Moments()
###########################################################################
###########################################################################
###########################################################################
    u_wife = np.empty(18)
    u_husband = np.empty(18)
    u_wife_full = np.empty(18)
    u_husband_full = np.empty(18)
    u_w_single_full = np.empty(13)
    u_h_single_full = np.empty(7)

    for draw_f in range(0, c.DRAW_F):   # start the forward loop for women
        wife = draw_wife.Wife()           # declare wife structure
        draw_wife.update_mother_char(wife, c.mother_f[0], c.mother_f[1], c.mother_f[2])
        # update ability by mother education and marital status
        draw_wife.update_ability_forward(wife)
        # make choices for all periods

        for t in range(0, c.max_period_f):
            wage_w_full, wage_w_part,_,_,_ = calculate_wage.calculate_wage_w(wife)
            single_women_value, single_women_index, single_women_ar = \
                calculate_utility_single_women(w_s_emax, wage_w_part, wage_w_full,0, wife, t, u_w_single_full, 0)
            married_index = -99
            choose_partner = 0
            if wife.get_married() == 0:    #  if not married - draw potential husband
                if wife.get_age() < 20:
                    prob_meet_potential_partner = np.exp(p.omega1)/(1.0+np.exp(p.omega1))
                elif single_women_index == 6 and wife.get_schooling() < 4:   #choose schooling
                    prob_meet_potential_partner = np.exp(p.omega2)/(1.0+np.exp(p.omega2))
                else:
                    prob_meet_potential_partner = meeting_partner.prob(wife.get_age())

                if wife.get_divorce() > 0 and prob_meet_potential_partner > 0.03:
                    prob_meet_potential_partner = 0.03  #np.exp(p.omega1)/(1.0+np.exp(p.omega1))

                assert prob_meet_potential_partner >= 0 and prob_meet_potential_partner <= 1, "invalid prob: " + str(prob_meet_potential_partner)

                temp = np.random.uniform()
                if temp < prob_meet_potential_partner:
                    choose_partner = 1
                    husband = draw_husband.draw_husband(wife, c.mother_f[0], c.mother_f[1], c.mother_f[2])

            if wife.get_married() == 1 or choose_partner == 1:
                wage_h_full, wage_h_part, _, _, _ = calculate_wage.calculate_wage_h(husband)
                home_time_h, home_time_w, home_time_h_preg, home_time_w_preg = \
                    calculate_utility_married(w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0, 0, wife, husband, t, u_wife, u_husband, u_wife_full, u_husband_full, 0)
                single_men_value, single_men_index, _ = calculate_utility_single_men(h_s_emax, wage_h_part, wage_h_full, 0, husband, t, u_h_single_full, 0)
                temp_husband = np.asarray(u_husband)
                temp_wife = np.asarray(u_wife)
                weighted_utility = float('-inf')
                married_index = -99
                for i in range(0, 18):
                    if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                        if c.bp_f * u_wife[i] + (1-c.bp_f) * u_husband[i] > weighted_utility:
                            weighted_utility = c.bp_f * u_wife[i] + (1-c.bp_f) * u_husband[i]
                            married_index = i
            #####################################################################################
            # update objects and moments = married
            #####################################################################################
            if married_index > -99:
                # the function update_married - updates wife and husband objects if they choose to get married
                update_married(husband, wife, married_index, home_time_h, home_time_w, home_time_h_preg, home_time_w_preg)
                # the function update moments - update
                if wife.get_age() > 29 and wife.get_age() < 41:
                    m.assortative_moments[husband.get_schooling(), wife.get_schooling()] += 1
                    m.assortative_counter[wife.get_schooling()] += 1

                m.fertility_moments_married[t, wife.get_kids()] += 1
                if wife.get_capacity() == 0:
                     temp = 0
                elif wife.get_capacity() == 0.5:
                     temp = 1
                elif wife.get_capacity() == 1:
                     temp = 2
                m.emp_moments_wife_married[t, temp] += 1  # 0 - unemployed, 1 - part time, 2 - full time
                if married_index > 5 and married_index < 12:    # wife work full time
                    m.wage_moments_wife_married[t] += wage_w_full
                    m.wage_counter_wife_married[t] += 1
                if married_index > 11:    # wife work part-time
                    m.wage_moments_wife_married[t] += (wage_w_part * 2)
                    m.wage_counter_wife_married[t] += 1
            #####################################################################################
            # update objects and moments = married
            #####################################################################################
            elif married_index == -99:  # not getting married
                update_wife_single(wife, single_women_index, single_women_ar)
                m.fertility_moments_single[t, wife.get_kids()] += 1
                if wife.get_capacity() == 0:
                    temp = 0
                elif wife.get_capacity() == 0.5:
                    temp = 1
                elif wife.get_capacity() == 1:
                    temp = 2
                m.emp_moments_wife_single[t, temp] += 1  # 0 - unemployed, 1 - part time, 2 - full time
                if single_women_index in c.single_women_full_time_index_array:  # choose full time employment
                    m.wage_moments_wife_single[t] += wage_w_full
                    m.wage_counter_wife_single[t] += 1
                    m.welfare_moments_employed[t] += wife.get_on_welfare()
                    m.welfare_counter_employed[t] += 1
                elif single_women_index in c.single_women_part_time_index_array:  # choose part-time employment
                    m.wage_moments_wife_single[t] += (wage_w_part * 2)
                    m.wage_counter_wife_single[t] += 1
                    m.welfare_moments_employed[t] += wife.get_on_welfare()
                    m.welfare_counter_employed[t] += 1
                if single_women_index in c.single_women_unemployed_index_array:   # choose welfare and unemployment
                    m.welfare_moments_unemployed[t] += wife.get_on_welfare()
                    m.welfare_counter_unemployed[t] += 1
            else:
                assert False, married_index

            if wife.get_age() < 32:
                m.school_moments_wife[t+1, wife.get_schooling()] += 1
            m.marriage_moments_w[t] += wife.get_married()
            m.divorce_moments_w[t] += wife.get_divorce()
            m.fertility_moments[t, wife.get_kids()] += 1
            #print(draw_f, t, wife.get_kids(), m.fertility_moments[t, :])
            # print(wife)
            # print(single_women_index)
            # print(married_index)
###########################################################################
#########################  MEN    ####################################
###########################################################################
    u_wife = np.empty(18)
    u_husband = np.empty(18)

    for draw_f in range(0, c.DRAW_F):  # start the forward loop for men
        husband = draw_husband.Husband()  # declare husband structure
        draw_husband.update_mother_char(husband, c.mother_f[0], c.mother_f[1], c.mother_f[2])
        # update ability by mother education and marital status
        draw_husband.update_ability_forward(husband)
        # make choices for all periods
        for t in range(0, c.max_period_f):
            wage_h_full, wage_h_part,_,_,_ = calculate_wage.calculate_wage_h(husband)
            single_men_value, single_men_index, single_men_ar = calculate_utility_single_men(
                h_s_emax, wage_h_part, wage_h_full, 0, husband, t, u_h_single_full, 0)
            married_index = -99
            choose_partner = 0
            if husband.get_married() == 0:  # if not married - draw potential husband
                if husband.get_age() < 20:
                    prob_meet_potential_partner = np.exp(p.omega1) / (1.0 + np.exp(p.omega1))
                elif single_men_index == 6:  # choose schooling
                    prob_meet_potential_partner = np.exp(p.omega2) / (1.0 + np.exp(p.omega2))
                else:
                    prob_meet_potential_partner = meeting_partner.prob(husband.get_age())

                assert prob_meet_potential_partner >= 0 and prob_meet_potential_partner <= 1, "invalid prob: " + str(prob_meet_potential_partner)

                temp = np.random.uniform()
                if temp < prob_meet_potential_partner:
                    choose_partner = 1
                    wife = draw_wife.draw_wife(husband, c.mother_f[0], c.mother_f[1], c.mother_f[2])

            if husband.get_married() == 1 or choose_partner == 1:
                wage_w_full, wage_w_part, _, _, _ = calculate_wage.calculate_wage_w(wife)
                home_time_h, home_time_w, home_time_h_preg, home_time_w_preg = calculate_utility_married(
                    w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0,0, wife, husband, t, u_wife, u_husband, u_wife_full, u_husband_full, 0)
                single_women_value, single_women_index, _ = calculate_utility_single_women(
                    w_s_emax, wage_w_part, wage_w_full,0, wife, t, u_w_single_full, 0)
                weighted_utility = float('-inf')
                married_index = -99
                for i in range(0, 18):
                    if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                        if c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i] > weighted_utility:
                            weighted_utility = c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i]
                            married_index = i
            #####################################################################################
            # update objects and moments = married
            #####################################################################################
            if married_index > -99:
                # the function update_married - updates wife and husband objects if they choose to get married
                update_married(husband, wife, married_index, home_time_h, home_time_w, home_time_h_preg, home_time_w_preg)
                if husband.get_capacity() == 0:
                    temp = 0
                elif husband.get_capacity() == 0.5:
                    temp = 1
                elif husband.get_capacity() == 1:
                    temp = 2
                m.emp_moments_husband_married[t, temp] += 1  # 0 - unemployed, 1 - part time, 2 - full time
                if married_index in c.men_full_index_array:  # husband work full time
                    m.wage_moments_husband_married[t] += wage_h_full
                    m.wage_counter_husband_married[t] += 1
                if married_index in c.men_part_index_array:  # wife work part time
                    m.wage_moments_husband_married[t] += (wage_h_part * 2)
                    m.wage_counter_husband_married[t] += 1
            #####################################################################################
            # update objects and moments = married
            #####################################################################################
            elif married_index == -99:  # not getting married
                update_husband_single(husband, single_men_index, single_men_ar)
                if husband.get_capacity() == 0:
                    temp = 0
                elif husband.get_capacity() == 0.5:
                    temp = 1
                elif husband.get_capacity() == 1:
                    temp = 2
                m.emp_moments_husband_single[t, temp] += 1  # 0 - unemployed, 1 - part time, 2 - full time
                if single_men_index == 2:  # choose full time employment
                    m.wage_moments_husband_single[t] += wage_h_full
                    m.wage_counter_husband_single[t] += 1
                elif single_men_index == 4:  # choose part-time employment
                    m.wage_moments_husband_single[t] += (wage_h_part * 2)
                    m.wage_counter_husband_single[t] += 1
            if husband.get_age() < 32:
                m.school_moments_husband[t+1 , husband.get_schooling()] += 1
            m.marriage_moments_h[t] += husband.get_married()
            m.divorce_moments_h[t] += husband.get_divorce()

        # print(wife)
            # print(single_women_index)
            # print(married_index)

    estimated_moments = calculate_moments(m, display_moments)
    return 0.0
