import numpy as np
from parameters import p
cimport value_to_index
cimport gross_to_net as tax
cimport constant_parameters as c
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
    int argmax(double arr[], int len)
from draw_wife cimport Wife
from value_to_index cimport ability_to_index, experience_to_index

cpdef tuple calculate_utility_single_women(double[:,:,:,:,:,:,:] w_s_emax,
        double wage_w_part, double wage_w_full, double tmp_w_full, Wife wife, int t, double[:] u_wife_full, int back,
        double temp_preg, int preg_possible):

    cdef double alimony_sum = 0
    cdef double net_income_single_w_ue = 0
    cdef double net_income_single_w_ef = 0
    cdef double net_income_single_w_ep = 0
    cdef double etaw = 0
    cdef double budget_c_single_w_ue = 0
    cdef double budget_c_single_w_ef = 0
    cdef double budget_c_single_w_ep = 0
    cdef double kids_utility = 0
    cdef double preg_utility_um = 0
    cdef double divorce_cost_w = 0
    cdef double[6] u_wife_single
    cdef double[6] u_wife
    cdef int kids_index = 0
    cdef int school_index = 0
    cdef double single_value = 0
    cdef int single_index = 0
    cdef double utility_kids = 0
    cdef double utility_leisure = 0
    cdef int kb5
    cdef int kb5_preg
    cdef int kids_minor = 0
    cdef int wife_exp_idx
    cdef int wife_exp_nxt
    cdef double p_ft
    cdef double p_pt


    ###################################################################################################
    #      calculate utility for single women
    ###################################################################################################
    if back == 1:
        wage_w_full_c = tmp_w_full
        wage_w_part_c = tmp_w_full * 0.5
    else:
        if wage_w_full > 0:
            wage_w_full_c = wage_w_full
        else:
            wage_w_full_c = 0
        if wage_w_part > 0:
            wage_w_part_c = wage_w_part
        else:
            wage_w_part_c = 0

    # Child benefit (AFDC-style) only paid when at least one kid is still a minor.
    # Backward: kid ages are not in the EMAX state space, so we approximate via period `t`
    #   -- pay full benefit up to t<=18 (wife age <=35, when even the earliest-born
    #   kid is still a minor); zero after, which understates rather than overstates.
    # Forward: wife.kb18 is tracked exactly, so use it.
    if wife.kids == 0:
        net_income_single_w_ue = c.ub_w
    else:
        if back == 1:
            kids_minor = wife.kids if t <= 18 else 0
        else:
            kids_minor = wife.kb18
        if kids_minor > 0:
            net_income_single_w_ue = c.ub_w + c.cb_const + c.cb_per_child * (kids_minor - 1)
        else:
            net_income_single_w_ue = c.ub_w
    net_income_single_w_ef = tax.gross_to_net_single(wife.kids, wage_w_full_c, t, back)  - c.childcare_cost * wife.kb5
    net_income_single_w_ep = tax.gross_to_net_single(wife.kids, wage_w_part_c, t, back)  - 0.6 * c.childcare_cost * wife.kb5

    # Childcare affordability check:
    # If childcare costs push net income below unemployment benefit (ub_w), the woman can't afford to work.
    # Setting wage = 0 triggers utility = -inf for that employment option later in the code
    # (see wage_w_full == 0 check below), effectively forcing the woman to stay home.
    # Net income is floored at ub_w to keep the budget positive and avoid NaN in pow(budget, alpha0).
    if net_income_single_w_ef < c.ub_w:
        wage_w_full = 0     # disables full-time option -> utility set to -inf later
        wage_w_full_c = 0
        net_income_single_w_ef = c.ub_w  # floor at UB so budget stays positive (avoids NaN)
    if net_income_single_w_ep < c.ub_w:
        wage_w_part = 0     # disables part-time option -> utility set to -inf later
        wage_w_part_c = 0
        net_income_single_w_ep = c.ub_w  # floor at UB so budget stays positive (avoids NaN)

    if wife.kids == 0:   # calculate values for wife in all cases
        etaw = 0
    elif wife.kids == 1:
        etaw = c.eta1            #this is the fraction of parent's income that one child gets
    elif wife.kids == 2:
        etaw = c.eta2
    elif wife.kids == 3:
        etaw = c.eta3
    else:
        assert False

    # net_income is guaranteed >= ub_w after childcare check, so budget is always positive
    budget_c_single_w_ue = (1-etaw)*net_income_single_w_ue
    budget_c_single_w_ef = (1-etaw)*net_income_single_w_ef
    budget_c_single_w_ep = (1-etaw)*net_income_single_w_ep

    #  utility from quality and quality of children: #row0 - CES  parameter row1_w - women leisure row1_h - husband leisure row2 -children

    utility_leisure = p.alpha2w0 * (c.leisure - c.home_p) + p.alpha2w1 * wife.kids * (c.leisure - c.home_p)
    utility_leisure_part = p.alpha2w0 * (c.leisure_part - c.home_p) + p.alpha2w1 * wife.kids * (c.leisure_part - c.home_p)

    if wife.kids > 0:
        kids_utility = cmath.pow(wife.kids, p.alpha4)
    elif wife.kids == 0:
        kids_utility = 0
    else:
        assert False

    # temp_preg is passed in: Gauss-Hermite node in backward, randn() in forward
    if wife.age < c.MAX_FERTILITY_AGE:
        preg_utility_um = p.preg_unmarried + p.preg_kids * wife.kids  + temp_preg
    else:
        preg_utility_um = float('-inf')

    # decision making - choose from up to 13 options, according  to CHOOSE_HUSBAND, CHOOSE_WORK, AGE  values
    # utility from each option:
    # single options:
    #            0-single + unemployed + non-pregnant
    #            1-single + unemployed + pregnant - zero for men
    #            2-single + employed full  + non-pregnant
    #            3-single + employed full  + pregnant   - zero for men
    #            4-single + employed part + non-pregnant
    #            5-single + employed part + pregnant   - zero for men
    #
    # wife current utility from each option:
    divorce_cost_w = p.dc_w
    u_wife_single[0] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue, p.alpha0) + \
        utility_leisure + p.alpha3_w_s * kids_utility + divorce_cost_w * wife.married
    if wife.age < c.MAX_FERTILITY_AGE:
        u_wife_single[1] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue, p.alpha0) + \
        utility_leisure + p.alpha3_w_s * kids_utility + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[1] = float('-inf')

    u_wife_single[2] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef, p.alpha0) + \
             p.alpha3_w_s * kids_utility + divorce_cost_w * wife.married
    if wife.age < c.MAX_FERTILITY_AGE:
        u_wife_single[3] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef, p.alpha0) + \
                p.alpha3_w_s * kids_utility + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[3] = float('-inf')

    u_wife_single[4] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep, p.alpha0) + \
            utility_leisure_part + p.alpha3_w_s * kids_utility + divorce_cost_w * wife.married
    if wife.age < c.MAX_FERTILITY_AGE:
        u_wife_single[5] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep, p.alpha0) + \
        utility_leisure_part + p.alpha3_w_s * kids_utility + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[5] = float('-inf')

    # calculate expected utility = current utility + emax value if t<T. = current utility + terminal value if t==T
    if t == c.max_period - 1:
        u_wife[0]= u_wife_single[0] + p.t1_w*wife.sc+p.t2_w*wife.cg + p.t6_w*wife.kids
        u_wife[1]= float('-inf') # can't get pregnant at 60
        u_wife[2]= u_wife_single[2] + p.t1_w*wife.sc+p.t2_w*wife.cg + p.t6_w*wife.kids #one more year of experience
        u_wife[3]= float('-inf') # can't get pregnant at 60
        u_wife[4]= u_wife_single[4] + p.t1_w*wife.sc+p.t2_w*wife.cg + p.t6_w*wife.kids #one more year of experience
        u_wife[5] = float('-inf') # can't get pregnant at 60

    #####################################################################   ADD EMAX    ########################
    # t - time 17-65
    # schooling - 5 levels grid
    # number of children - 4 level grid - 0, 1, 2 , 3+
    # ability_index - 3 level grid
    # kids below 5 - 4 levels
    # we - employed - 2 levels grid
    # w_s_emax[t][school][kids][ability][kb5][we]
    # need to take care of experience and number of children when calling the EMAX:
    # if women is pregnant, add 1 to the number of children unless the number is already 4
    elif t < c.max_period - 1:
        wife_ability_index = ability_to_index(wife.ability_i)
        # Next-period experience bucket. UNEMP stays at wife_exp_idx; FT/PT advance to
        # wife_exp_nxt with prob p_ft/p_pt. Forward (back==0): deterministic (p in {0,1})
        # from the true continuous experience. Backward (back==1): probabilistic advance
        # p = increment / bucket_width (uniform-within-bucket), consistent in expectation
        # with forward accumulation. (See calculate_utility_married for the same logic.)
        wife_exp_idx = experience_to_index(wife.experience)
        wife_exp_nxt = wife_exp_idx + 1
        if wife_exp_nxt > 3:
            wife_exp_nxt = 3
        if back == 1:
            if wife_exp_idx == 0:
                p_ft = 1.0 / 2.5
                p_pt = 0.5 / 2.5
            elif wife_exp_idx == 1:
                p_ft = 1.0 / 3.0
                p_pt = 0.5 / 3.0
            elif wife_exp_idx == 2:
                p_ft = 1.0 / 5.0
                p_pt = 0.5 / 5.0
            else:
                p_ft = 0.0
                p_pt = 0.0
        else:
            p_ft = 1.0 if experience_to_index(wife.experience + 1.0) > wife_exp_idx else 0.0
            p_pt = 1.0 if experience_to_index(wife.experience + 0.5) > wife_exp_idx else 0.0

        # w_s_emax[t, school, kids, ability, kb5, wife_exp_idx, we]
        kb5 = wife.kb5
        kb5_preg = min(3, wife.kb5 + 1)

        # options 0-1: unemployed, non-pregnant / pregnant (no experience advance)
        u_wife[0] = u_wife_single[0] + c.beta0 * w_s_emax[t+1, wife.schooling, wife.kids, wife_ability_index, kb5, wife_exp_idx, c.UNEMP]
        if wife.age < c.MAX_FERTILITY_AGE and wife.kids < 3:
            kids_index = wife.kids+1
            u_wife[1] = u_wife_single[1] + c.beta0 * w_s_emax[t+1, wife.schooling, kids_index, wife_ability_index, kb5_preg, wife_exp_idx, c.UNEMP]
        else:
            u_wife[1] = float('-inf')

        # options 2-3: employed full, non-pregnant / pregnant (advance with p_ft)
        u_wife[2] = u_wife_single[2] + c.beta0 * ((1.0-p_ft)*w_s_emax[t+1, wife.schooling, wife.kids, wife_ability_index, kb5, wife_exp_idx, c.EMP] + p_ft*w_s_emax[t+1, wife.schooling, wife.kids, wife_ability_index, kb5, wife_exp_nxt, c.EMP])
        if  wife.age < c.MAX_FERTILITY_AGE and wife.kids < 3:
            kids_index = wife.kids+1
            u_wife[3] = u_wife_single[3] + c.beta0 * ((1.0-p_ft)*w_s_emax[t+1, wife.schooling, kids_index, wife_ability_index, kb5_preg, wife_exp_idx, c.EMP] + p_ft*w_s_emax[t+1, wife.schooling, kids_index, wife_ability_index, kb5_preg, wife_exp_nxt, c.EMP])
        else:
            u_wife[3] = float('-inf')
        # options 4-5: employed part, non-pregnant / pregnant (advance with p_pt)
        u_wife[4] = u_wife_single[4] + c.beta0 * ((1.0-p_pt)*w_s_emax[t+1, wife.schooling, wife.kids, wife_ability_index, kb5, wife_exp_idx, c.EMP] + p_pt*w_s_emax[t+1, wife.schooling, wife.kids, wife_ability_index, kb5, wife_exp_nxt, c.EMP])
        if wife.age < c.MAX_FERTILITY_AGE and wife.kids < 3:
            kids_index =  wife.kids+1
            u_wife[5] = u_wife_single[5] + c.beta0 * ((1.0-p_pt)*w_s_emax[t+1, wife.schooling, kids_index, wife_ability_index, kb5_preg, wife_exp_idx, c.EMP] + p_pt*w_s_emax[t+1, wife.schooling, kids_index, wife_ability_index, kb5_preg, wife_exp_nxt, c.EMP])
        else:
            u_wife[5] = float('-inf')

    else:
        assert False

    for i in range(0, 6):
        u_wife_full[i] = u_wife[i]

    if wife.age > c.MAX_FERTILITY_AGE or wife.kids == 3:   # can't get pregnant after 40
        u_wife[1] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[5] = float('-inf')
    elif preg_possible == 0:  # biological pregnancy shock said "no" this period
        u_wife[1] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[5] = float('-inf')
    if wage_w_full == 0:
        u_wife[2] = float('-inf')
        u_wife[3] = float('-inf')
    if wage_w_part == 0:
        u_wife[4] = float('-inf')
        u_wife[5] = float('-inf')

    ###################################################################################
    single_index = argmax(u_wife, 6)
    single_value = u_wife[single_index]
    return single_value, single_index
