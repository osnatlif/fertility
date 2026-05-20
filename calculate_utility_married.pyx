import numpy as np
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
    void fill(double arr[], int len, double value)
from parameters import p
from value_to_index cimport ability_to_index

cimport gross_to_net as tax
from draw_husband cimport Husband
from draw_wife cimport Wife
cimport constant_parameters as c


cpdef tuple calculate_utility_married(double[:,:,:,:,:,:,:,:,:,:] w_emax,
    double[:,:,:,:,:,:,:,:,:,:] h_emax,
    double wage_h_part, double wage_h_full, double wage_w_part, double wage_w_full,
    double tmp_full_h, double tmp_full_w, Wife wife, Husband husband, int t,
    double[:] u_wife, double[:] u_husband, double[:] u_wife_full, double[:] u_husband_full, int back,
    double temp, double temp_preg, int preg_possible):
    #####################################################################################################
    ##### declare variables anf initilize
    #####################################################################################################
    cdef double net_income_married_Wue_Hue = 0
    cdef double net_income_married_Wue_Hef = 0
    cdef double net_income_married_Wue_Hep = 0
    cdef double net_income_married_Wef_Hue = 0
    cdef double net_income_married_Wef_Hef = 0
    cdef double net_income_married_Wef_Hep = 0
    cdef double net_income_married_Wep_Hue = 0
    cdef double net_income_married_Wep_Hef = 0
    cdef double net_income_married_Wep_Hep = 0
    cdef double etaw = 0
    cdef double budget_c_married_Wue_Hue = 0
    cdef double budget_c_married_Wue_Hef = 0
    cdef double budget_c_married_Wue_Hep = 0
    cdef double budget_c_married_Wef_Hue = 0
    cdef double budget_c_married_Wef_Hef = 0
    cdef double budget_c_married_Wef_Hep = 0
    cdef double budget_c_married_Wep_Hue = 0
    cdef double budget_c_married_Wep_Hef = 0
    cdef double budget_c_married_Wep_Hep = 0
    cdef double preg_utility = float('-inf')
    cdef double marriage_utility = 0
    cdef double marriage_cost_h = 0
    cdef double marriage_cost_w = 0
    cdef double[18] uc_wife
    cdef double[18] uc_husband
    cdef double mq_draw
    cdef int kb5
    cdef int kb5_preg
    cdef int mq
    cdef double temp_h
    cdef double temp_w
    cdef double utility_leisure = 0
    cdef double utility_leisure_part = 0
    cdef double utility_number_kids = 0
    cdef double wage_h_part_c = 0
    cdef double wage_h_full_c = 0
    cdef double wage_w_part_c = 0
    cdef double wage_w_full_c = 0
    # in variables' names: first index wife, second husband

    # if married, kids only at wife object.if consider getting married, add both kids
    if back == 1:
        wage_w_full_c = tmp_full_w
        wage_w_part_c = tmp_full_w * 0.5
        wage_h_full_c = tmp_full_h
        wage_h_part_c = tmp_full_h * 0.5
    else:
        if wage_w_full > 0:
            wage_w_full_c = wage_w_full
        else:
            wage_w_full_c = 0
        if wage_w_part > 0:
            wage_w_part_c = wage_w_part
        else:
            wage_w_part_c = 0
        if wage_h_full > 0:
            wage_h_full_c = wage_h_full
        else:
            wage_h_full_c = 0
        if wage_h_part > 0:
            wage_h_part_c = wage_h_part
        else:
            wage_h_part_c = 0

    net_income_married_Wue_Hue  = c.ub_w + c.ub_h
    net_income_married_Wue_Hef  = c.ub_w + tax.gross_to_net_married(wife.kids,   0   , wage_h_full_c, t, back)
    net_income_married_Wue_Hep  = c.ub_w + tax.gross_to_net_married(wife.kids,   0   , wage_h_part_c, t, back)
    ###############
    net_income_married_Wef_Hue  = c.ub_h + tax.gross_to_net_married(wife.kids, wage_w_full_c,  0         , t, back) - c.childcare_cost * wife.kb5
    net_income_married_Wef_Hef  =          tax.gross_to_net_married(wife.kids, wage_w_full_c, wage_h_full_c , t, back) - c.childcare_cost * wife.kb5
    net_income_married_Wef_Hep  =          tax.gross_to_net_married(wife.kids, wage_w_full_c, wage_h_part_c , t, back) - 0.6 * c.childcare_cost * wife.kb5
    ###################
    net_income_married_Wep_Hue = c.ub_h + tax.gross_to_net_married(wife.kids, wage_w_part_c,    0       , t, back) - c.childcare_cost * wife.kb5
    net_income_married_Wep_Hef =          tax.gross_to_net_married(wife.kids, wage_w_part_c, wage_h_full_c, t, back) - c.childcare_cost * wife.kb5
    net_income_married_Wep_Hep =          tax.gross_to_net_married(wife.kids, wage_w_part_c, wage_h_part_c, t, back) - 0.6 * c.childcare_cost * wife.kb5

    # Childcare affordability check:
    # If childcare costs push net income below ub_w for any wife-employed combination,
    # the woman can't afford to work in that scenario.
    # Setting net_income = -inf marks the option as infeasible. The budget is floored at 1.0
    # below to prevent NaN from pow(-inf, alpha0). After utility computation, the corresponding
    # uc_wife[i] and uc_husband[i] entries are explicitly set to -inf (see override block below).
    if net_income_married_Wef_Hue < c.ub_w:
       net_income_married_Wef_Hue = float('-inf')
    if net_income_married_Wef_Hef  < c.ub_w:
        net_income_married_Wef_Hef = float('-inf')
    if net_income_married_Wef_Hep < c.ub_w:
        net_income_married_Wef_Hep = float('-inf')
    if net_income_married_Wep_Hue < c.ub_w:
        net_income_married_Wep_Hue = float('-inf')
    if net_income_married_Wep_Hef < c.ub_w:
        net_income_married_Wep_Hef = float('-inf')
    if net_income_married_Wep_Hep < c.ub_w:
        net_income_married_Wep_Hep = float('-inf')

    # budget constraint
    if wife.kids == 0:  # calculate values for wife in all cases
        etaw = 0
    elif wife.kids == 1:
        etaw = c.eta1  #this is the fraction of parent's income that one child gets
    elif wife.kids == 2:
        etaw = c.eta2
    elif wife.kids == 3:
        etaw = c.eta3
    else:
        assert False

    # Budget floor of 1.0 on wife-employed options prevents NaN from pow(-inf, alpha0).
    # The computed utility is meaningless for infeasible options - it is overridden to -inf
    # after the utility computation block (see "set utility to -inf for infeasible options" below).
    budget_c_married_Wue_Hue  = (1-etaw)*net_income_married_Wue_Hue * c.scale
    budget_c_married_Wue_Hef  = (1-etaw)*net_income_married_Wue_Hef * c.scale
    budget_c_married_Wue_Hep  = (1-etaw)*net_income_married_Wue_Hep * c.scale
    ############
    budget_c_married_Wef_Hue  = max(1.0, (1-etaw)*net_income_married_Wef_Hue * c.scale)
    budget_c_married_Wef_Hef  = max(1.0, (1-etaw)*net_income_married_Wef_Hef * c.scale)
    budget_c_married_Wef_Hep  = max(1.0, (1-etaw)*net_income_married_Wef_Hep * c.scale)
    ###########
    budget_c_married_Wep_Hue  = max(1.0, (1-etaw)*net_income_married_Wep_Hue * c.scale)
    budget_c_married_Wep_Hef  = max(1.0, (1-etaw)*net_income_married_Wep_Hef * c.scale)
    budget_c_married_Wep_Hep  = max(1.0, (1-etaw)*net_income_married_Wep_Hep * c.scale)

    utility_leisure_w = p.alpha2w0 * (c.leisure - c.home_p) + p.alpha2w1 * wife.kids * (c.leisure - c.home_p)
    utility_leisure_w_part = p.alpha2w0 * (c.leisure_part - c.home_p) + p.alpha2w1 * wife.kids * (c.leisure_part - c.home_p)
    utility_leisure_h = p.alpha2h0 * (c.leisure - c.home_p) + p.alpha2h1 * husband.kids * (c.leisure - c.home_p)
    utility_leisure_h_part = p.alpha2h0 * (c.leisure_part - c.home_p) + p.alpha2h1 * husband.kids * (c.leisure_part - c.home_p)

    # I assume that each kid get 20% (eta1). if the family has 2 kids, each gets 20%, yet the total is 32% (eta2) since part is common
    if wife.kids > 0:
        # first index wife, second husband
        kids_utility = cmath.pow(wife.kids, p.alpha4)
    elif wife.kids == 0:
        kids_utility = 0

    # pregnancy preference utility uses temp_preg passed in from caller
    # (in backward: Gauss-Hermite node; in forward: drawn N(0, sigma_p))
    if wife.age < c.MAX_FERTILITY_AGE:
        preg_utility = p.preg_married + p.preg_kids * wife.kids + temp_preg
    else:
        preg_utility = float('-inf')
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # match-quality residual `temp` is passed in: zero for new marriages and in singles backward,
    # GH node in married_couple_emax backward, randn() in forward for continuing marriages.
    if back == 0 and wife.married == 0:
        # draw match quality: low, medium, or high (equal probability)
        mq_draw = uniform()
        if mq_draw < 1.0/3.0:
            wife.match_quality = c.match_vector[0]  # low
        elif mq_draw < 2.0/3.0:
            wife.match_quality = c.match_vector[1]  # medium
        else:
            wife.match_quality = c.match_vector[2]  # high

    if wife.schooling == husband.schooling == 0:
        marriage_utility = p.taste_hs + wife.match_quality + temp  # utility from marriage - same education
    elif wife.schooling == husband.schooling == 1:
        marriage_utility = p.taste_sc + wife.match_quality + temp  # utility from marriage - husband more educated
    elif wife.schooling == husband.schooling == 2:
        marriage_utility = p.taste_cg + wife.match_quality + temp  # utility from marriage - husband more educated
    else:
        marriage_utility = p.mconst + wife.match_quality + temp  # utility from marriage - wife more educated
    marriage_cost_h = p.mc
    marriage_cost_w = p.mc
    # marriage options:# first index wife, second husband
    # 0-married + women unemployed  +man unemployed     +non-pregnant
    # 1-married + women unemployed  +man unemployed     +pregnant
    # 2-married + women unemployed  +man employed full  +non-pregnant
    # 3-married + women unemployed  +man employed full  +pregnant
    # 4-married + women unemployed  +man employed part  +non-pregnant
    # 5-married + women unemployed  +man employed part  +pregnant
    # 6-married + women employed full   +man unemployed     +non-pregnant
    # 7-married + women employed full   +man unemployed     +pregnant
    # 8-married + women employed full   +man employed full  +non-pregnant
    # 9-married + women employed full +man employed full  +pregnant
    # 10-married + women employed full +man employed part  +non-pregnant
    # 11-married + women employed full +man employed part  +pregnant
    # 12-married + women employed part  +man unemployed     +non-pregnant
    # 13-married + women employed part +man unemployed     +pregnant
    # 14-married + women employed part +man employed full  +non-pregnant
    # 15-married + women employed part +man employed full  +pregnant
    # 16-married + women employed part +man employed part  +non-pregnant
    # 17-married + women employed part  +man employed part  +pregnant
    # marriage options:# first index wife, second husband
    fill(uc_wife, 18, float("-inf"))
    fill(uc_husband, 18, float("-inf"))

    uc_wife[0] = marriage_utility + (1/p.alpha0) * cmath.pow(budget_c_married_Wue_Hue, p.alpha0) + marriage_cost_w * (1-wife.married) + \
                 utility_leisure_w + p.alpha3_w_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[1] = marriage_utility + (1/p.alpha0) * cmath.pow(budget_c_married_Wue_Hue, p.alpha0) + marriage_cost_w * (1-wife.married) + \
                 utility_leisure_w + p.alpha3_w_m * kids_utility + preg_utility
    uc_husband[0] = marriage_utility + (1/p.alpha0) * cmath.pow(budget_c_married_Wue_Hue, p.alpha0) + marriage_cost_h * (1 - husband.married) + \
                    utility_leisure_h + p.alpha3_h_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[1] = marriage_utility + (1/p.alpha0) * cmath.pow(budget_c_married_Wue_Hue, p.alpha0) + marriage_cost_h * (1 - husband.married) + \
                    utility_leisure_h + p.alpha3_h_m * kids_utility + preg_utility

    uc_wife[2] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hef, p.alpha0) + marriage_cost_w * (1 - wife.married) + \
                 utility_leisure_w + p.alpha3_w_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[3] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hef,p.alpha0) + marriage_cost_w * (1 - wife.married) + \
                     utility_leisure_w + p.alpha3_w_m * kids_utility + preg_utility
    uc_husband[2] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hef, p.alpha0) + marriage_cost_h * (
                                1 - husband.married) + p.alpha3_h_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[3] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hef, p.alpha0) + marriage_cost_h * (
                                1 - husband.married) + \
                        p.alpha3_h_m * kids_utility + preg_utility
    uc_wife[4] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hep, p.alpha0) + marriage_cost_w * (1 - wife.married) + \
                     utility_leisure_w + p.alpha3_w_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[5] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hep, p.alpha0) + marriage_cost_w * (1 - wife.married) + \
                    utility_leisure_w + p.alpha3_w_m * kids_utility + preg_utility
    uc_husband[4] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hep, p.alpha0) + marriage_cost_h * ( 1 - husband.married) + \
                        utility_leisure_h_part + p.alpha3_h_m * kids_utility
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[5] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wue_Hep, p.alpha0) + marriage_cost_h * (1 - husband.married) + \
                        utility_leisure_h_part + p.alpha3_h_m * kids_utility + preg_utility
    uc_wife[6] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hue, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (1 - wife.married)
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[7] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hue, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (1 - wife.married) + preg_utility
    uc_husband[6] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hue, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                   1 - husband.married) + utility_leisure_h
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[7] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hue, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_w * (
                                1 - husband.married) + preg_utility + utility_leisure_h
    uc_wife[8] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hef,  p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                 1 - wife.married)
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[9] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hef, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                 1 - wife.married) + preg_utility
    uc_husband[8] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hef, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                    1 - husband.married)
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[9] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hef, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                    1 - husband.married) + preg_utility
    uc_wife[10] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hep, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married)
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[11] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hep, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married) + preg_utility
    uc_husband[10] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hep, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married) + utility_leisure_h_part
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[11] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wef_Hep, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married) + utility_leisure_h_part + preg_utility
     ##################################################################################################################
    uc_wife[12] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hue, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                              1 - wife.married) + utility_leisure_w_part
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[13] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hue, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                              1 - wife.married) +  utility_leisure_w_part + preg_utility
    uc_husband[12] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hue, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                 1 - husband.married) +  utility_leisure_h
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[13] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hue, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                 1 - husband.married) +  utility_leisure_h + preg_utility
    uc_wife[14] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hef, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married) + utility_leisure_w_part
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[15] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hef, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married) +  utility_leisure_w_part + preg_utility
    uc_husband[14] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hef, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married)
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[15] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hef, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married) + preg_utility
    uc_wife[16] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hep, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married)+  utility_leisure_w_part
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_wife[17] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hep, p.alpha0) + p.alpha3_w_m * kids_utility + marriage_cost_w * (
                                  1 - wife.married) +  utility_leisure_w_part + preg_utility
    uc_husband[16] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hep, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married) + utility_leisure_h_part
    if wife.age < c.MAX_FERTILITY_AGE:
        uc_husband[17] = marriage_utility + (1 / p.alpha0) * cmath.pow(budget_c_married_Wep_Hep, p.alpha0) + p.alpha3_h_m * kids_utility + marriage_cost_h * (
                                     1 - husband.married) +  utility_leisure_h_part + preg_utility

    # set utility to -inf for infeasible options where childcare exceeds income
    if net_income_married_Wef_Hue == float('-inf'):
        uc_wife[6] = float('-inf')
        uc_wife[7] = float('-inf')
        uc_husband[6] = float('-inf')
        uc_husband[7] = float('-inf')
    if net_income_married_Wef_Hef == float('-inf'):
        uc_wife[8] = float('-inf')
        uc_wife[9] = float('-inf')
        uc_husband[8] = float('-inf')
        uc_husband[9] = float('-inf')
    if net_income_married_Wef_Hep == float('-inf'):
        uc_wife[10] = float('-inf')
        uc_wife[11] = float('-inf')
        uc_husband[10] = float('-inf')
        uc_husband[11] = float('-inf')
    if net_income_married_Wep_Hue == float('-inf'):
        uc_wife[12] = float('-inf')
        uc_wife[13] = float('-inf')
        uc_husband[12] = float('-inf')
        uc_husband[13] = float('-inf')
    if net_income_married_Wep_Hef == float('-inf'):
        uc_wife[14] = float('-inf')
        uc_wife[15] = float('-inf')
        uc_husband[14] = float('-inf')
        uc_husband[15] = float('-inf')
    if net_income_married_Wep_Hep == float('-inf'):
        uc_wife[16] = float('-inf')
        uc_wife[17] = float('-inf')
        uc_husband[16] = float('-inf')
        uc_husband[17] = float('-inf')

    ##################################################################################################
    ##################################################################################################
    ########               add emax or terminal value                                         ########
    ##################################################################################################
    ##################################################################################################
    if t == c.max_period - 1:
        u_wife[0] = uc_wife[0] + p.t1_w*wife.sc + p.t2_w*wife.cg + p.t3_w*husband.sc + p.t4_w*husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[0] = uc_husband[0] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[1] = float('-inf')
        u_husband[1] = float('-inf')
        u_wife[2] =    uc_wife[2]    + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[2] = uc_husband[2] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[3] = float('-inf')
        u_husband[3]= float('-inf')
        u_wife[4] =       uc_wife[4] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[4] = uc_husband[4] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[5] = float('-inf')
        u_husband[5] = float('-inf')
        u_wife[6] = uc_wife[6] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[6] = uc_husband[6] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[7] = float('-inf')
        u_husband[7] = float('-inf')
        u_wife[8] = uc_wife[8] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[8] = uc_husband[8] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[9] = float('-inf')
        u_husband[9] = float('-inf')
        u_wife[10] = uc_wife[10] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[10] = uc_husband[10] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[11]= float('-inf')
        u_husband[11] = float('-inf')
        u_wife[12] = uc_wife[12] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[12] = uc_husband[12] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[13]= float('-inf')
        u_husband[13] = float('-inf')
        u_wife[14] = uc_wife[14] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[14] = uc_husband[14] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[15]= float('-inf')
        u_husband[15] = float('-inf')
        u_wife[16] = uc_wife[16] + p.t1_w * wife.sc + p.t2_w * wife.cg + p.t3_w * husband.sc + p.t4_w * husband.cg + p.t5_w + p.t6_w*wife.kids
        u_husband[16] = uc_husband[16] + p.t1_h * wife.sc + p.t2_h * wife.cg + p.t3_h * husband.sc + p.t4_h * husband.cg + p.t5_h + p.t6_h*wife.kids
        u_wife[17] = float('-inf')
        u_husband[17] = float('-inf')

    elif t < c.max_period - 1:
        # t is not the terminal period so add emax
        # t - time 17-65
        # HS,wife.schooling - schooling - 3 levels grid
        # C_N, H_N , W_N - number of kids - 4 level grid
        # ability_h_index,ability_w_index - 3 level grid

        #######################################
        # add emax to men and women's utility
        #######################################
        wife_ability_index = ability_to_index(wife.ability_i)
        husband_ability_index = ability_to_index(husband.ability_i)
        if wife.kids < 3:
            kids_preg = wife.kids + 1   # if pregnant - add another kid to emax, but only up to 3 kids
        else:
            kids_preg = 3
        # EMAX indices for new dimensions
        kb5 = wife.kb5
        kb5_preg = min(3, wife.kb5 + 1)
        mq = wife.match_quality_i

        # EMAX by (wife_emp, husband_emp) combination — non-pregnant and pregnant variants
        # w_emax[t, school_w, school_h, kids, ability_w, ability_h, kb5, we, he, mq]
        # (UNEMP, UNEMP) — wife unemployed, husband unemployed
        emax_w_uu      = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.UNEMP, c.UNEMP, mq]
        emax_h_uu      = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.UNEMP, c.UNEMP, mq]
        emax_w_uu_preg = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.UNEMP, c.UNEMP, mq]
        emax_h_uu_preg = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.UNEMP, c.UNEMP, mq]
        # (UNEMP, EMP) — wife unemployed, husband employed
        emax_w_ue      = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.UNEMP, c.EMP, mq]
        emax_h_ue      = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.UNEMP, c.EMP, mq]
        emax_w_ue_preg = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.UNEMP, c.EMP, mq]
        emax_h_ue_preg = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.UNEMP, c.EMP, mq]
        # (EMP, UNEMP) — wife employed, husband unemployed
        emax_w_eu      = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.EMP, c.UNEMP, mq]
        emax_h_eu      = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.EMP, c.UNEMP, mq]
        emax_w_eu_preg = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.EMP, c.UNEMP, mq]
        emax_h_eu_preg = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.EMP, c.UNEMP, mq]
        # (EMP, EMP) — wife employed, husband employed
        emax_w_ee      = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.EMP, c.EMP, mq]
        emax_h_ee      = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, wife.kids,      wife_ability_index, husband_ability_index, kb5,      c.EMP, c.EMP, mq]
        emax_w_ee_preg = c.beta0 * w_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.EMP, c.EMP, mq]
        emax_h_ee_preg = c.beta0 * h_emax[t+1, wife.schooling, husband.schooling, kids_preg, wife_ability_index, husband_ability_index, kb5_preg, c.EMP, c.EMP, mq]

        # options 0-1: wife unemployed, husband unemployed (UNEMP, UNEMP)
        u_wife[0]     = uc_wife[0]     + emax_w_uu
        u_husband[0]  = uc_husband[0]  + emax_h_uu
        u_wife[1]     = uc_wife[1]     + emax_w_uu_preg
        u_husband[1]  = uc_husband[1]  + emax_h_uu_preg
        # options 2-3: wife unemployed, husband employed full (UNEMP, EMP)
        u_wife[2]     = uc_wife[2]     + emax_w_ue
        u_husband[2]  = uc_husband[2]  + emax_h_ue
        u_wife[3]     = uc_wife[3]     + emax_w_ue_preg
        u_husband[3]  = uc_husband[3]  + emax_h_ue_preg
        # options 4-5: wife unemployed, husband employed part (UNEMP, EMP)
        u_wife[4]     = uc_wife[4]     + emax_w_ue
        u_husband[4]  = uc_husband[4]  + emax_h_ue
        u_wife[5]     = uc_wife[5]     + emax_w_ue_preg
        u_husband[5]  = uc_husband[5]  + emax_h_ue_preg
        # options 6-7: wife employed full, husband unemployed (EMP, UNEMP)
        u_wife[6]     = uc_wife[6]     + emax_w_eu
        u_husband[6]  = uc_husband[6]  + emax_h_eu
        u_wife[7]     = uc_wife[7]     + emax_w_eu_preg
        u_husband[7]  = uc_husband[7]  + emax_h_eu_preg
        # options 8-9: wife employed full, husband employed full (EMP, EMP)
        u_wife[8]     = uc_wife[8]     + emax_w_ee
        u_husband[8]  = uc_husband[8]  + emax_h_ee
        u_wife[9]     = uc_wife[9]     + emax_w_ee_preg
        u_husband[9]  = uc_husband[9]  + emax_h_ee_preg
        # options 10-11: wife employed full, husband employed part (EMP, EMP)
        u_wife[10]    = uc_wife[10]    + emax_w_ee
        u_husband[10] = uc_husband[10] + emax_h_ee
        u_wife[11]    = uc_wife[11]    + emax_w_ee_preg
        u_husband[11] = uc_husband[11] + emax_h_ee_preg
        # options 12-13: wife employed part, husband unemployed (EMP, UNEMP)
        u_wife[12]    = uc_wife[12]    + emax_w_eu
        u_husband[12] = uc_husband[12] + emax_h_eu
        u_wife[13]    = uc_wife[13]    + emax_w_eu_preg
        u_husband[13] = uc_husband[13] + emax_h_eu_preg
        # options 14-15: wife employed part, husband employed full (EMP, EMP)
        u_wife[14]    = uc_wife[14]    + emax_w_ee
        u_husband[14] = uc_husband[14] + emax_h_ee
        u_wife[15]    = uc_wife[15]    + emax_w_ee_preg
        u_husband[15] = uc_husband[15] + emax_h_ee_preg
        # options 16-17: wife employed part, husband employed part (EMP, EMP)
        u_wife[16]    = uc_wife[16]    + emax_w_ee
        u_husband[16] = uc_husband[16] + emax_h_ee
        u_wife[17]    = uc_wife[17]    + emax_w_ee_preg
        u_husband[17] = uc_husband[17] + emax_h_ee_preg

    for i in range(0, 18):
        u_wife_full[i] = u_wife[i]
        u_husband_full[i] = u_husband[i]

    if wife.age >= c.MAX_FERTILITY_AGE or wife.kids == 3:   # can't get pregnant after 40
        u_wife[1] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[5] = float('-inf')
        u_wife[7] = float('-inf')
        u_wife[9] = float('-inf')
        u_wife[11] = float('-inf')
        u_wife[13] = float('-inf')
        u_wife[15] = float('-inf')
        u_wife[17] = float('-inf')
        u_husband[1] = float('-inf')
        u_husband[3] = float('-inf')
        u_husband[5] = float('-inf')
        u_husband[7] = float('-inf')
        u_husband[9] = float('-inf')
        u_husband[11] = float('-inf')
        u_husband[13] = float('-inf')
        u_husband[15] = float('-inf')
        u_husband[17] = float('-inf')
    elif preg_possible == 0:  # biological pregnancy shock said "no" this period
        u_wife[1] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[5] = float('-inf')
        u_wife[7] = float('-inf')
        u_wife[9] = float('-inf')
        u_wife[11] = float('-inf')
        u_wife[13] = float('-inf')
        u_wife[15] = float('-inf')
        u_wife[17] = float('-inf')
        u_husband[1] = float('-inf')
        u_husband[3] = float('-inf')
        u_husband[5] = float('-inf')
        u_husband[7] = float('-inf')
        u_husband[9] = float('-inf')
        u_husband[11] = float('-inf')
        u_husband[13] = float('-inf')
        u_husband[15] = float('-inf')
        u_husband[17] = float('-inf')
    if wage_w_full == 0:
        u_wife[6] = float('-inf')
        u_wife[7] = float('-inf')
        u_wife[8] = float('-inf')
        u_wife[9] = float('-inf')
        u_wife[10] = float('-inf')
        u_wife[11] = float('-inf')
        u_husband[6] = float('-inf')
        u_husband[7] = float('-inf')
        u_husband[8] = float('-inf')
        u_husband[9] = float('-inf')
        u_husband[10] = float('-inf')
        u_husband[11] = float('-inf')
    if wage_w_part == 0:
        u_wife[12] = float('-inf')
        u_wife[13] = float('-inf')
        u_wife[14] = float('-inf')
        u_wife[15] = float('-inf')
        u_wife[16] = float('-inf')
        u_wife[17] = float('-inf')
        u_husband[12] = float('-inf')
        u_husband[13] = float('-inf')
        u_husband[14] = float('-inf')
        u_husband[15] = float('-inf')
        u_husband[16] = float('-inf')
        u_husband[17] = float('-inf')
    if wage_h_full == 0:
        u_wife[2] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[8] = float('-inf')
        u_wife[9] = float('-inf')
        u_wife[14] = float('-inf')
        u_wife[15] = float('-inf')
        u_husband[2] = float('-inf')
        u_husband[3] = float('-inf')
        u_husband[8] = float('-inf')
        u_husband[9] = float('-inf')
        u_husband[14] = float('-inf')
        u_husband[15] = float('-inf')
    if wage_h_part == 0:
        u_wife[4] = float('-inf')
        u_wife[5] = float('-inf')
        u_wife[10] = float('-inf')
        u_wife[11] = float('-inf')
        u_wife[16] = float('-inf')
        u_wife[17] = float('-inf')
        u_husband[4] = float('-inf')
        u_husband[5] = float('-inf')
        u_husband[10] = float('-inf')
        u_husband[11] = float('-inf')
        u_husband[16] = float('-inf')
        u_husband[17] = float('-inf')

    return ()
