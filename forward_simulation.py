import numpy as np
import cohorts
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

MAX_AGE = 50   # all education levels end at age 50

def _age_group_idx(age):
    # DIAGNOSTIC: map age to 5-year group (matches the marriage/divorce table)
    if 22 <= age <= 26: return 0
    if 27 <= age <= 31: return 1
    if 32 <= age <= 36: return 2
    if 37 <= age <= 41: return 3
    if 42 <= age <= 46: return 4
    return -1


def forward_simulation(w_emax, h_emax, w_s_emax, h_s_emax, verbose, display_moments):
    seed(1)
    np.random.seed(1)
    m = Moments()
    # Initial-condition kid distribution at entry age, by edu_level (rows: HS/SC/CG+,
    # cols: P(kids=0), P(kids=1), P(kids=2)). See appendix_initial_conditions.tex.
    # Loaded once; converted to integer counts per edu so that exactly the right
    # number of wives are assigned each initial kid state (no stochastic draw).
    _initial_kids_p = np.loadtxt("input/initial_kids_" + cohorts.cohort + ".txt")
    # DIAGNOSTIC: stay-home rate among mothers with at least one kid below 5.
    # Last dim: 0 = married, 1 = single. Increment AFTER the period update,
    # so wife.capacity = chosen labor choice and wife.kb5 = end-of-period state.
    _N_EDU = c.school_size_f
    _N_AG = 5
    _kb5_total = np.zeros((_N_EDU, _N_AG, 2))
    _kb5_stay  = np.zeros((_N_EDU, _N_AG, 2))
    # DIAGNOSTIC: marriage selection by husband ability (rows: ability 0/1/2, cols: age group).
    _husb_total   = np.zeros((3, _N_AG))   # husband-period observations
    _husb_married = np.zeros((3, _N_AG))   # of which married this period
    _husb_wifeab  = np.zeros((3, _N_AG))   # sum of wife ability_i when married (for avg)
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
      # Deterministic integer counts of initial-kid states for this edu.
      # Last bucket absorbs rounding so the three counts sum to exactly DRAW_F.
      _n0 = int(round(_initial_kids_p[edu_level, 0] * c.DRAW_F))
      _n1 = int(round(_initial_kids_p[edu_level, 1] * c.DRAW_F))
      _n2 = c.DRAW_F - _n0 - _n1
      for draw_f in range(0, c.DRAW_F):   # start the forward loop for women - 5000 draws per education level
        wife = draw_wife.Wife()           # declare wife structure
        wife.schooling = edu_level        # fix education level (exogenous)
        wife.set_age(start_age)
        draw_wife.update_wife_schooling(wife)
        draw_wife.update_ability_forward(wife)
        # Assign initial kids deterministically based on draw_f position within the edu cell.
        # See appendix_initial_conditions.tex. Wife stays single at entry.
        if draw_f < _n0:
            init_kids = 0
        elif draw_f < _n0 + _n1:
            init_kids = 1
        else:
            init_kids = 2
        draw_wife.initialize_wife_kids(wife, init_kids)
        # make choices for all periods

        for t in range(0, n_periods):
            period = wife.get_age() - 17          # universal period matching backward solution
            age_idx = wife.get_age() - 18         # index for annual moments (0=age18, 37=age55)
            wage_w_full, wage_w_part,_,_,_ = calculate_wage.calculate_wage_w(wife, period)

            # Draw period shocks for this wife: same values are passed to both single_women and married utility,
            # so the bilateral decision is consistent.
            temp_q = np.random.normal(0, p.sigma_q) if wife.get_married() == 1 else 0.0
            temp_preg = np.random.normal(0, p.sigma_p)
            if wife.get_age() >= c.MAX_FERTILITY_AGE_f or wife.get_kids() == 3:
                preg_possible = 0
            else:
                preg_possible = 1 if np.random.uniform() <= c.preg_prob_f[wife.get_age() - 18] else 0

            single_women_value, single_women_index = \
                calculate_utility_single_women(w_s_emax, wage_w_part, wage_w_full,0, wife, period, u_w_single_full, 0,
                                               temp_preg, preg_possible)
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
                calculate_utility_married(w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0, 0, wife, husband, period, u_wife, u_husband, u_wife_full, u_husband_full, 0,
                                          temp_q, temp_preg, preg_possible)
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
                if married_index > -99:
                    assert u_wife[married_index] > single_women_value, (married_index, u_wife[married_index], single_women_value)
                    assert u_husband[married_index] > single_men_value, (married_index, u_husband[married_index], single_men_value)
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
            # DIAGNOSTIC: stay-home rate among mothers with at least one kid <5
            _ag = _age_group_idx(wife.get_age())
            if _ag >= 0 and wife.get_kb5() > 0:
                _marital_idx = 0 if wife.get_married() == 1 else 1
                _kb5_total[edu_level, _ag, _marital_idx] += 1
                if wife.get_capacity() == 0:
                    _kb5_stay[edu_level, _ag, _marital_idx] += 1
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

                # Draw shocks for the wife in this period (consistent between married and single_women calls).
                temp_q = np.random.normal(0, p.sigma_q) if wife.get_married() == 1 else 0.0
                temp_preg = np.random.normal(0, p.sigma_p)
                if wife.get_age() >= c.MAX_FERTILITY_AGE_f or wife.get_kids() == 3:
                    preg_possible = 0
                else:
                    preg_possible = 1 if np.random.uniform() <= c.preg_prob_f[wife.get_age() - 18] else 0

                calculate_utility_married(
                    w_emax, h_emax, wage_h_part, wage_h_full, wage_w_part, wage_w_full, 0,0, wife, husband, period, u_wife, u_husband, u_wife_full, u_husband_full, 0,
                    temp_q, temp_preg, preg_possible)
                single_women_value, single_women_index = calculate_utility_single_women(
                    w_s_emax, wage_w_part, wage_w_full,0, wife, period, u_w_single_full, 0,
                    temp_preg, preg_possible)
                weighted_utility = float('-inf')
                married_index = -99
                for i in range(0, 18):
                    if u_wife[i] > single_women_value and u_husband[i] > single_men_value:
                        if c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i] > weighted_utility:
                            weighted_utility = c.bp_f * u_wife[i] + (1 - c.bp_f) * u_husband[i]
                            married_index = i
                if married_index > -99:
                    assert u_wife[married_index] > single_women_value, (married_index, u_wife[married_index], single_women_value)
                    assert u_husband[married_index] > single_men_value, (married_index, u_husband[married_index], single_men_value)
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
            # DIAGNOSTIC: marriage selection by husband ability
            _agm = _age_group_idx(husband.get_age())
            if _agm >= 0:
                _ab = husband.get_ability_i()
                _husb_total[_ab, _agm] += 1
                if husband.get_married() == 1:
                    _husb_married[_ab, _agm] += 1
                    _husb_wifeab[_ab, _agm] += wife.get_ability_i()

    # ---- Group C: aggregate moment closure ----
    # every observed (edu, age) woman-period is either married or single (and contributes to fertility counters too)
    for e in range(c.school_size_f):
        for a in range(m.emp_wife_married.shape[1]):
            married_count = m.emp_wife_married[e, a, :].sum()
            single_count = m.emp_wife_single[e, a, :].sum()
            assert married_count + single_count == m.total_w[e, a], \
                f"women emp split != total at (edu={e}, age={a}): married={married_count}, single={single_count}, total={m.total_w[e, a]}"
            assert m.fertility_count_married[e, a] + m.fertility_count_unmarried[e, a] == m.total_w[e, a], \
                f"women fertility counts != total at (edu={e}, age={a})"

    # DIAGNOSTICS (stay-home rate; marriage selection by husband ability).
    # Gated behind display_moments so they stay silent during the estimation search.
    if display_moments:
        print()
        print("=" * 80)
        print("DIAGNOSTIC: STAY-HOME RATE AMONG MOTHERS WITH KID(S) BELOW AGE 5")
        print("  Denominator: women-period observations with wife.kb5 > 0")
        print("  Numerator:   subset at capacity == 0 (chose to stay home this period)")
        print("=" * 80)
        _edu_labels = ["HS", "SC", "CG+"]
        _ag_labels = ["22-26", "27-31", "32-36", "37-41", "42-46"]
        for _marital_idx, _mlabel in [(0, "MARRIED MOTHERS"), (1, "SINGLE MOTHERS")]:
            print(f"\n  === {_mlabel} ===")
            print(f"  {'edu':<5}{'age':<8}{'N_moms':>10}{'N_stay':>10}{'stay_rate':>12}")
            print(f"  {'-'*5}{'-'*8}{'-'*10}{'-'*10}{'-'*12}")
            for _e in range(_N_EDU):
                for _a in range(_N_AG):
                    tot = _kb5_total[_e, _a, _marital_idx]
                    stay = _kb5_stay[_e, _a, _marital_idx]
                    rate = (stay / tot) if tot > 0 else float('nan')
                    print(f"  {_edu_labels[_e]:<5}{_ag_labels[_a]:<8}{int(tot):>10}{int(stay):>10}{rate:>12.3f}")

        print()
        print("=" * 80)
        print("DIAGNOSTIC: MARRIAGE SELECTION BY HUSBAND ABILITY")
        print("  marr_rate = fraction of husband-periods married, by husband ability")
        print("  avg_wifeab = mean wife ability_i (0/1/2) conditional on married")
        print("=" * 80)
        _ab_labels = ["low", "med", "high"]
        for _ab in range(3):
            print(f"\n  === husband ability = {_ab_labels[_ab]} ===")
            print(f"  {'age':<8}{'N':>10}{'marr_rate':>12}{'avg_wifeab':>12}")
            print(f"  {'-'*8}{'-'*10}{'-'*12}{'-'*12}")
            for _a in range(_N_AG):
                tot = _husb_total[_ab, _a]
                marr = _husb_married[_ab, _a]
                mrate = (marr / tot) if tot > 0 else float('nan')
                wab = (_husb_wifeab[_ab, _a] / marr) if marr > 0 else float('nan')
                print(f"  {_ag_labels[_a]:<8}{int(tot):>10}{mrate:>12.3f}{wab:>12.3f}")

    estimated_moments = calculate_moments(m, display_moments)
    return estimated_moments
