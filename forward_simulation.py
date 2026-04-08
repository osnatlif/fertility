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

MAX_AGE = 55   # all education levels end at age 55

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
    u_w_single_full = np.empty(6)
    u_h_single_full = np.empty(6)

    for edu_level in range(0, c.school_size_f):   # education is exogenous: loop over education levels
      start_age = c.AGE_VALUES_f[edu_level]
      n_periods = MAX_AGE - start_age + 1         # HS=38, SC=36, CG=34
      for draw_f in range(0, c.DRAW_F):   # start the forward loop for women - 5000 draws per education level
        wife = draw_wife.Wife()           # declare wife structure
        wife.schooling = edu_level        # fix education level (exogenous)
        wife.set_age(start_age)
        draw_wife.update_wife_schooling(wife)
        draw_wife.update_ability_forward(wife)
        # make choices for all periods

        for t in range(0, n_periods):
            period = wife.get_age() - 17          # universal period matching backward solution
            age_idx = wife.get_age() - 18         # index for annual moments (0=age18, 37=age55)
            wage_w_full, wage_w_part,_,_,_ = calculate_wage.calculate_wage_w(wife, period)
            single_women_value, single_women_index = \
                calculate_utility_single_women(w_s_emax, wage_w_part, wage_w_full,0, wife, period, u_w_single_full, 0)
            married_index = -99
            choose_partner = 0
            if wife.get_married() == 0 and wife.get_age() <= 55:    #  if not married - draw potential husband
                prob_meet_potential_partner = meeting_partner.prob(wife.get_age())
                assert prob_meet_potential_partner >= 0 and prob_meet_potential_partner <= 1, "invalid prob: " + str(prob_meet_potential_partner)

                temp = np.random.uniform()
                if temp < prob_meet_potential_partner:
                    choose_partner = 1
                    husband = draw_husband.draw_husband(wife)

            if wife.get_married() == 1 or choose_partner == 1:
                wage_h_full, wage_h_part, _, _, _ = calculate_wage.calculate_wage_h(husband, period)
                calculate_utility_married(w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0, 0, wife, husband, period, u_wife, u_husband, u_wife_full, u_husband_full, 0)
                single_men_value, single_men_index = calculate_utility_single_men(h_s_emax, wage_h_part, wage_h_full, 0, husband, period, u_h_single_full, 0)
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
                update_married(husband, wife, married_index)
                # assortative mating - women's perspective (ages 42-46 only)
                if 42 <= wife.get_age() <= 46:
                    m.assortative_w[edu_level, husband.get_schooling()] += 1
                    m.assortative_counter_w[edu_level] += 1
                # employment
                if wife.get_capacity() == 0:
                     temp = 0
                elif wife.get_capacity() == 0.5:
                     temp = 1
                elif wife.get_capacity() == 1:
                     temp = 2
                m.emp_wife_married[edu_level, age_idx, temp] += 1
                # wages
                if married_index > 5 and married_index < 12:    # wife work full time
                    m.wage_wife_married[edu_level, age_idx] += wage_w_full
                    m.wage_counter_wife_married[edu_level, age_idx] += 1
                if married_index > 11:    # wife work part-time
                    m.wage_wife_married[edu_level, age_idx] += (wage_w_part * 2)
                    m.wage_counter_wife_married[edu_level, age_idx] += 1
                # fertility
                m.fertility_total_married[edu_level, age_idx] += wife.get_kids()
                m.fertility_count_married[edu_level, age_idx] += 1
                if wife.get_kids() == 0:
                    m.childless_married[edu_level, age_idx] += 1
            #####################################################################################
            # update objects and moments = single
            #####################################################################################
            elif married_index == -99:  # not getting married
                update_wife_single(wife, single_women_index)
                # employment
                if wife.get_capacity() == 0:
                    temp = 0
                elif wife.get_capacity() == 0.5:
                    temp = 1
                elif wife.get_capacity() == 1:
                    temp = 2
                m.emp_wife_single[edu_level, age_idx, temp] += 1
                # wages
                if single_women_index in c.single_women_full_time_index_array:
                    m.wage_wife_single[edu_level, age_idx] += wage_w_full
                    m.wage_counter_wife_single[edu_level, age_idx] += 1
                elif single_women_index in c.single_women_part_time_index_array:
                    m.wage_wife_single[edu_level, age_idx] += (wage_w_part * 2)
                    m.wage_counter_wife_single[edu_level, age_idx] += 1
                # fertility
                m.fertility_total_unmarried[edu_level, age_idx] += wife.get_kids()
                m.fertility_count_unmarried[edu_level, age_idx] += 1
                if wife.get_kids() == 0:
                    m.childless_unmarried[edu_level, age_idx] += 1
            else:
                assert False, married_index

            m.total_w[edu_level, age_idx] += 1
            m.marriage_w[edu_level, age_idx] += wife.get_married()
            m.divorce_w[edu_level, age_idx] += wife.get_divorce()
###########################################################################
#########################  MEN    ####################################
###########################################################################
    u_wife = np.empty(18)
    u_husband = np.empty(18)

    for edu_level in range(0, c.school_size_f):   # education is exogenous: loop over education levels
      start_age = c.AGE_VALUES_f[edu_level]
      n_periods = MAX_AGE - start_age + 1
      for draw_f in range(0, c.DRAW_F):  # start the forward loop for men - 5000 draws per education level
        husband = draw_husband.Husband()  # declare husband structure
        husband.schooling = edu_level     # fix education level (exogenous)
        husband.set_age(start_age)
        draw_husband.update_school(husband)
        draw_husband.update_ability_forward(husband)
        # make choices for all periods
        for t in range(0, n_periods):
            period = husband.get_age() - 17       # universal period matching backward solution
            age_idx = husband.get_age() - 18      # index for annual moments
            wage_h_full, wage_h_part,_,_,_ = calculate_wage.calculate_wage_h(husband, period)
            single_men_value, single_men_index = calculate_utility_single_men(
                h_s_emax, wage_h_part, wage_h_full, 0, husband, period, u_h_single_full, 0)
            married_index = -99
            choose_partner = 0
            if husband.get_married() == 0 and husband.get_age() <= 55:  # if not married - draw potential wife
                prob_meet_potential_partner = meeting_partner.prob(husband.get_age())

                assert prob_meet_potential_partner >= 0 and prob_meet_potential_partner <= 1, "invalid prob: " + str(prob_meet_potential_partner)

                temp = np.random.uniform()
                if temp < prob_meet_potential_partner:
                    choose_partner = 1
                    wife = draw_wife.draw_wife(husband)

            if husband.get_married() == 1 or choose_partner == 1:
                wage_w_full, wage_w_part, _, _, _ = calculate_wage.calculate_wage_w(wife, period)
                calculate_utility_married(
                    w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0,0, wife, husband, period, u_wife, u_husband, u_wife_full, u_husband_full, 0)
                single_women_value, single_women_index = calculate_utility_single_women(
                    w_s_emax, wage_w_part, wage_w_full,0, wife, period, u_w_single_full, 0)
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
                update_married(husband, wife, married_index)
                # assortative mating - men's perspective (ages 42-46 only)
                if 42 <= husband.get_age() <= 46:
                    m.assortative_h[edu_level, wife.get_schooling()] += 1
                    m.assortative_counter_h[edu_level] += 1
                # employment
                if husband.get_capacity() == 0:
                    temp = 0
                elif husband.get_capacity() == 0.5:
                    temp = 1
                elif husband.get_capacity() == 1:
                    temp = 2
                m.emp_husband_married[edu_level, age_idx, temp] += 1
                # wages
                if married_index in c.men_full_index_array:  # husband work full time
                    m.wage_husband_married[edu_level, age_idx] += wage_h_full
                    m.wage_counter_husband_married[edu_level, age_idx] += 1
                if married_index in c.men_part_index_array:  # husband work part time
                    m.wage_husband_married[edu_level, age_idx] += (wage_h_part * 2)
                    m.wage_counter_husband_married[edu_level, age_idx] += 1
            #####################################################################################
            # update objects and moments = single
            #####################################################################################
            elif married_index == -99:  # not getting married
                update_husband_single(husband, single_men_index)
                if husband.get_capacity() == 0:
                    temp = 0
                elif husband.get_capacity() == 0.5:
                    temp = 1
                elif husband.get_capacity() == 1:
                    temp = 2
                m.emp_husband_single[edu_level, age_idx, temp] += 1
                if single_men_index == 2:  # choose full time employment
                    m.wage_husband_single[edu_level, age_idx] += wage_h_full
                    m.wage_counter_husband_single[edu_level, age_idx] += 1
                elif single_men_index == 4:  # choose part-time employment
                    m.wage_husband_single[edu_level, age_idx] += (wage_h_part * 2)
                    m.wage_counter_husband_single[edu_level, age_idx] += 1

            m.total_h[edu_level, age_idx] += 1
            m.marriage_h[edu_level, age_idx] += husband.get_married()
            m.divorce_h[edu_level, age_idx] += husband.get_divorce()

    estimated_moments = calculate_moments(m, display_moments)
    return estimated_moments
