import numpy as np
from parameters import p
from value_to_index cimport ability_to_index
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    int argmax(double arr[], int len)
cimport gross_to_net as tax
cimport constant_parameters as c
from draw_husband cimport Husband

cpdef tuple calculate_utility_single_men(double[:,:,:,:] h_s_emax,
    double wage_h_part, double wage_h_full, double tmp_full_h, Husband husband, int t, double[:] u_husband_full, int back):
    ###################################################################################################
    #      calculate utility for single man
    ###################################################################################################

    cdef double net_income_single_h_ue = 0
    cdef double net_income_single_h_ef = 0
    cdef double net_income_single_h_ep = 0
    cdef double etah = 0
    cdef double budget_c_single_h_ue = 0
    cdef double budget_c_single_h_ef = 0
    cdef double budget_c_single_h_ep = 0
    cdef double kids_utility = 0
    cdef double utility_leisure = 0
    cdef double utility_leisure_part = 0
    cdef double divorce_cost_h = 0
    cdef double[7] u_husband_single
    cdef double[7] u_husband
    cdef double single_value = 0
    cdef int single_index = 0
    cdef double wage_h_full_c = 0
    cdef double wage_h_part_c = 0
    net_income_single_h_ue = c.ub_h
    if back == 1:
        wage_h_full_c = tmp_full_h
        wage_h_part_c = tmp_full_h * 0.5
    elif back == 0:
        if wage_h_full > 0:
            wage_h_full_c = wage_h_full
        else:
            wage_h_full_c = 0
        if wage_h_part > 0:
            wage_h_part_c = wage_h_part
        else:
            wage_h_part_c = 0
    else:
        assert False

    net_income_single_h_ef = tax.gross_to_net_single(husband.kids, wage_h_full_c, t, back)
    net_income_single_h_ep = tax.gross_to_net_single(husband.kids, wage_h_part_c, t, back)

    if husband.kids == 0:  # calculate value of husband if there is husband
        etah = 0
    elif husband.kids == 1:
        etah = c.eta1  # this is the fraction of parent's income that one child gets
    elif husband.kids == 2:
        etah = c.eta2
    elif husband.kids == 3:
        etah = c.eta3
    else:
        assert (0)
    # net_income is guaranteed >= ub_h, so budget is always positive
    budget_c_single_h_ue = (1 - etah) * net_income_single_h_ue
    budget_c_single_h_ef = (1 - etah) * net_income_single_h_ef
    budget_c_single_h_ep = (1 - etah) * net_income_single_h_ep
    # utility from quality and quality of children: #row0 - CES  parameter row1 - women leisure row2 - husband leisure row3 -income
    kids_utility = cmath.pow(husband.kids, p.alpha4)
    utility_leisure = p.alpha2h0 * (c.leisure - c.home_p)
    utility_leisure_part = p.alpha2h0 * (c.leisure_part - c.home_p)
    # decision making - choose from up to 13 options, according to CHOOSE_HUSBAND, CHOOSE_WORK, AGE  values
    # utility from each option:
    # single options:
    #            0-singe + unemployed + non-pregnant
    #            2-singe + employed full  + non-pregnant
    #            4-singe + employed part + non-pregnant
    # husband current utility from each option:
    divorce_cost_h = p.dc_h
    ##########################################################################################################
    u_husband_single[1] = float('-inf')    # single husband can't get pregnant
    u_husband_single[3] = float('-inf')    # single husband can't get pregnant
    u_husband_single[5] = float('-inf')    # single husband can't get pregnant
    # husband (potential husband) current utility from each option:
    u_husband_single[0] = (1 / p.alpha0) * cmath.pow(budget_c_single_h_ue, p.alpha0) + \
           utility_leisure + p.alpha3_h_s * kids_utility + divorce_cost_h * husband.married
    u_husband_single[2] = (1 / p.alpha0) * cmath.pow(budget_c_single_h_ef, p.alpha0) + \
                              p.alpha3_h_s * kids_utility + divorce_cost_h * husband.married
    u_husband_single[4] = (1 / p.alpha0) * cmath.pow(budget_c_single_h_ep, p.alpha0) + \
            utility_leisure_part + p.alpha3_h_s * kids_utility + divorce_cost_h * husband.married
    # calculate expected utility = current utility + emax value if t<T. = current utility + terminal value if t==T

    if t == c.max_period -1:
        u_husband[0] = u_husband_single[0] + p.t3_h*husband.sc+p.t4_h*husband.cg + p.t6_h*husband.kids
        u_husband[1] = float('-inf') # can't get pregnant at 60
        u_husband[2] = u_husband_single[2] + p.t3_h*husband.sc+p.t4_h*husband.cg + p.t6_h*husband.kids #one more year of experience
        u_husband[3] = float('-inf') # can't get pregnant at 60
        u_husband[4] = u_husband_single[4] + p.t3_h*husband.sc+p.t4_h*husband.cg + p.t6_h*husband.kids #one more year of experience
        u_husband[5] = float('-inf') # can't get pregnant at 60

    #####################################################################   ADD EMAX    ########################
    # t - time 18-60
    # schooling - 3 levels grid
    # number of children - 4 level grid
    # ability_index - 3 level grid
    # he - employed last period - 2 levels
    # h_s_emax[t][school][kids][ability][he]
    # need to take care of experience and number of children when calling the EMAX:
    # if women is pregnant, add 1 to the number of children unless the number is already 4
    elif t < c.max_period - 1:
        husband_ability_index = ability_to_index(husband.ability_i)

        # h_s_emax[t, school, kids, ability, he]
        # option 0: unemployed
        u_husband[0] = u_husband_single[0] + c.beta0 * h_s_emax[t+1, husband.schooling, husband_ability_index, c.UNEMP]
        u_husband[1] = float('-inf') # single men can't get pregnant
        # option 2: employed full
        u_husband[2] = u_husband_single[2] + c.beta0 * h_s_emax[t+1, husband.schooling, husband_ability_index, c.EMP]
        u_husband[3] = float('-inf')
        # option 4: employed part
        u_husband[4] = u_husband_single[4] + c.beta0 * h_s_emax[t+1, husband.schooling, husband_ability_index, c.EMP]
        u_husband[5] = float('-inf')

    else:
        assert False
    ###################################################################################

    for i in range(0, 6):
        u_husband_full[i] = u_husband[i]

    if wage_h_full == 0:
        u_husband[2] = float('-inf')
    if wage_h_part == 0:
        u_husband[4] = float('-inf')
    single_index = argmax(u_husband, 6)
    single_value = u_husband[single_index]

    return single_value, single_index
