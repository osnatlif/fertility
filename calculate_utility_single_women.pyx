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
from value_to_index cimport ability_to_index
from value_to_index cimport exp_to_index
from value_to_index cimport home_time_to_index

cpdef tuple calculate_utility_single_women(double[:,:,:,:,:,:,:,:,:] w_s_emax,
        double wage_w_part, double wage_w_full, double tmp_w_full, Wife wife, int t, double[:] u_wife_full, int back):

    cdef double welfare_stigma_cost = 0
    cdef double alimony_sum = 0
    cdef double net_income_single_w_ue = 0
    cdef double net_income_single_w_ue_welfare = 0
    cdef double net_income_single_w_ef =0
    cdef double net_income_single_w_ef_welfare= 0
    cdef double net_income_single_w_ep = 0
    cdef double net_income_single_w_ep_welfare = 0
    cdef double welfare = 0
    cdef double etaw = 0
    cdef double budget_c_single_w_ue = 0
    cdef double budget_c_single_w_ue_welfare = 0
    cdef double budget_c_single_w_ef = 0
    cdef double budget_c_single_w_ef_welfare = 0
    cdef double budget_c_single_w_ep = 0
    cdef double budget_c_single_w_ep_welfare = 0
    cdef double kids_utility_single_w_ue = 0
    cdef double kids_utility_single_w_ue_welfare = 0
    cdef double kids_utility_single_w_ef = 0
    cdef double kids_utility_single_w_ef_welfare = 0
    cdef double kids_utility_single_w_ep = 0
    cdef double kids_utility_single_w_ep_welfare = 0
    cdef double preg_utility_um = 0
    cdef double school_utility_w = 0
    cdef double home_time_w = 0
    cdef double home_time_w_preg = 0
    cdef double divorce_cost_w = 0
    cdef double[13] u_wife_single
    cdef double[13] u_wife
    cdef int kids_index = 0
    cdef int wife_exp_index = 0
    cdef int wife_home_time_index = 0
    cdef int wife_home_time_index_preg = 0
    cdef int school_index = 0
    cdef double single_value = 0
    cdef int single_index = 0
    cdef double ar = 0
    cdef int wife_mother_educ_index = 0
    cdef int wife_mother_marital_index = 0
    cdef double utility_kids = 0
    cdef double utility_leisure = 0
    cdef double temp_w
    cdef double temp_preg
    cdef double temp

    # get specific cohort data
    if c.cohort == 1960:
        if back == 1:   # the 1996 reform was at age 36 for 1960 cohort
            welfare_stigma_cost = p.stigma
        elif wife.age < 36 and back == 0:
            welfare_stigma_cost = p.stigma
        elif wife.age > 35 and back == 0:
            welfare_stigma_cost = p.stigma96

    elif c.cohort == 1970:
        if back == 1:
            welfare_stigma_cost = p.stigma
        elif wife.age < 28 and back == 0:   # the 1996 reform was at age 28-24 for 1970 cohort
            welfare_stigma_cost = p.stigma
        else:
            welfare_stigma_cost = p.stigma96
    elif c.cohort == 1980:
        welfare_stigma_cost = p.stigma96    # always under the 1996 reform
    elif c.cohort == 1990 or c.cohort == 2000 or c.cohort == 2010:
        welfare_stigma_cost = p.stigma96   # always under the 1996 reform
    else:
        assert False

    ###################################################################################################
    #      calculate utility for single women
    ###################################################################################################
    if back == 1:
        temp = 1
    else:
        temp = uniform()

    alimony_sum = 0
    if wife.divorce == 1 or wife.married == 1:
        if wife.kids > 0 and temp < p.p_alimony:
            alimony_sum = p.alimony
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


    if wife.kids == 0:
        net_income_single_w_ue = c.ub_w  # if single and unemployed with no kids - only unemployment benefit
        net_income_single_w_ef = tax.gross_to_net_single(wife.kids, wage_w_full_c, t, back) + alimony_sum
        net_income_single_w_ep = tax.gross_to_net_single(wife.kids, wage_w_part_c, t, back) + alimony_sum
    else:
        # if the women have children, and she divorced - she gets alimony with sum estimated probability
        welfare = c.constant_welfare + c.by_kids_welfare * wife.kids + c.by_income_welfare * 0 + welfare_stigma_cost
        net_income_single_w_ue = c.ub_w + c.cb_const + c.cb_per_child*(wife.kids-1) + alimony_sum   # unemployment benefit + child benefit (minus 1 since the constant include 1 child
        net_income_single_w_ue_welfare = net_income_single_w_ue + welfare # unemployment benefit + child benefit (minus 1 since the constant include 1 child

        welfare = c.constant_welfare + c.by_kids_welfare * wife.kids + c.by_income_welfare * wage_w_full_c + welfare_stigma_cost
        net_income_single_w_ef = tax.gross_to_net_single(wife.kids, wage_w_full_c, t, back) + alimony_sum
        net_income_single_w_ef_welfare = net_income_single_w_ef  + welfare

        welfare = c.constant_welfare + c.by_kids_welfare * wife.kids + c.by_income_welfare * wage_w_part_c + welfare_stigma_cost
        net_income_single_w_ep = tax.gross_to_net_single(wife.kids, wage_w_part_c, t, back) + alimony_sum
        net_income_single_w_ep_welfare = net_income_single_w_ep + alimony_sum + welfare

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

    budget_c_single_w_ue = (1-etaw)*net_income_single_w_ue
    if wife.kids > 0:
        budget_c_single_w_ue_welfare = (1-etaw)*net_income_single_w_ue_welfare
    budget_c_single_w_ef = (1-etaw)*net_income_single_w_ef
    if wife.kids > 0:
            budget_c_single_w_ef_welfare = (1 - etaw) * net_income_single_w_ef_welfare
    budget_c_single_w_ep = (1-etaw)*net_income_single_w_ep
    if wife.kids > 0:
         budget_c_single_w_ep_welfare = (1-etaw)*net_income_single_w_ep_welfare

    #  utility from quality and quality of children: #row0 - CES  parameter row1_w - women leisure row1_h - husband leisure row2 -children
    if wife.kids > 0:
        utility_kids = cmath.pow(wife.kids, p.row2)
        utility_leisure = p.row1_w * cmath.pow(c.leisure - c.home_p, p.row0)
        utility_leisure_part = p.row1_w * cmath.pow(c.leisure_part - c.home_p, p.row0)

        kids_utility_single_w_ue         = cmath.pow(utility_leisure + (1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ue, p.row0), 1.0/p.row0) * utility_kids
        kids_utility_single_w_ue_welfare = cmath.pow(utility_leisure + (1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ue_welfare, p.row0), 1.0/p.row0) * utility_kids
        kids_utility_single_w_ef         = cmath.pow((1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ef, p.row0), 1.0/p.row0) * utility_kids
        kids_utility_single_w_ef_welfare = cmath.pow((1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ef_welfare, p.row0), 1.0/p.row0) * utility_kids
        kids_utility_single_w_ep         = cmath.pow(utility_leisure_part + (1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ep, p.row0),1.0/p.row0) * utility_kids
        kids_utility_single_w_ep_welfare = cmath.pow(utility_leisure_part + (1.0 - p.row1_w)*cmath.pow(c.eta1*net_income_single_w_ep_welfare, p.row0), 1.0/p.row0) * utility_kids
        #print("utility_kids")
        #print(utility_kids)
        #print(utility_leisure)
        #print(utility_leisure_part)
        #print(kids_utility_single_w_ue)
        #print(kids_utility_single_w_ef)
        #print(kids_utility_single_w_ep)
        #print(p.row2*cmath.pow(c.eta1*net_income_single_w_ep, p.row0))

    elif wife.kids == 0:
        kids_utility_single_w_ue = 0
        kids_utility_single_w_ef = 0
        kids_utility_single_w_ep = 0
        kids_utility_single_w_ue_welfare = 0
        kids_utility_single_w_ef_welfare = 0
        kids_utility_single_w_ep_welfare = 0
    else:
        assert False

    if back == 1:
        temp_preg = 0
    else:
        temp_preg = randn(0, p.sigma_p)

    if wife.age < 40:
        preg_utility_um = p.preg_unmarried + p.preg_const + p.preg_kids * wife.kids + p.preg_t_minus1 * wife.preg + p.health * wife.age + temp_preg
    else:
        preg_utility_um = float('-inf')

    school_utility_w = 0
    if wife.schooling == 0 and wife.age < 31:   # if hsd - don't pay tuition
        school_utility_w = p.s1_w + p.s2_w * wife.mother_educ + p.s3_w * wife.ability_value  # utility from high school
    elif wife.schooling > 0 and wife.age < 31:  # if hsg or higher - need to pay tuition
        school_utility_w = p.s1_w + p.s2_w * wife.mother_educ + p.s3_w * wife.ability_value + p.s4_w  # utility rom post high  school
    else:
        school_utility_w = float('-inf')
    # Home time equation - random walk: tau2_w - pregnancy in previous period, tau1_w - drift term - should be negative
    if back == 1:
        temp_w = 0
    else:
        temp_w = randn(0, p.sigma_hp_w)

    home_time_w =  cmath.exp((p.tau1_w * cmath.log(wife.home_time_ar)) + p.tau0_w + temp_w)
    if wife.age < 40:
        home_time_w_preg = cmath.exp((p.tau1_w * cmath.log(wife.home_time_ar)) + p.tau0_w + p.tau2_w + temp_w)
    else:
        home_time_w_preg = float('-inf')
        # decision making - choose from up to 13 options, according  to CHOOSE_HUSBAND, CHOOSE_WORK, AGE  values
    # utility from each option:
    # single options:
    #            0-single + unemployed + non-pregnant
    #                    1-single + unemployed + pregnant - zero for men
    #            2-single + employed full  + non-pregnant
    #            3-single + employed full  + pregnant   - zero for men
    #            4-single + employed part + non-pregnant
    #            5-single + employed part + pregnant   - zero for men
    #            6-schooling: single + unemployed + non-pregnant + no children
    #            7-single + unemployed + non-pregnant + welfare
    #                    8-single + unemployed + pregnant + welfare - zero for men
    #            9-single + employed full  + non-pregnant + welfare
    #            10-single + employed full  + pregnant + welfare  - zero for men
    #            11 -single + employed part + non-pregnant + welfare
    #            12-single + employed part + pregnant + welfare  - zero for men
    # wife current utility from each option:
    divorce_cost_w = p.dc_w + p.dc_w_kids * wife.kids
    utility_leisure = cmath.pow(c.leisure - c.home_p, p.alpha2)
    utility_leisure_part = cmath.pow(c.leisure_part - c.home_p, p.alpha2)
    u_wife_single[0] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue, p.alpha0) + \
        ((              p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure + \
             p.alpha3_w_s * kids_utility_single_w_ue + home_time_w + divorce_cost_w * wife.married
    if wife.age < 40:
        u_wife_single[1] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue, p.alpha0) +   \
            ((p.alpha11_w + p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure + \
            p.alpha3_w_s * kids_utility_single_w_ue + home_time_w_preg + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[1] = float('-inf')

    u_wife_single[2] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef, p.alpha0) + \
             p.alpha3_w_s * kids_utility_single_w_ef + divorce_cost_w * wife.married
    if  wife.age < 40:
        u_wife_single[3] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef, p.alpha0) + \
                p.alpha3_w_s * kids_utility_single_w_ef + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[3] = float('-inf')

    u_wife_single[4] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep, p.alpha0) + \
            ((              p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure_part \
             + p.alpha3_w_s * kids_utility_single_w_ep + home_time_w * 0.5 + divorce_cost_w * wife.married
    
    if  wife.age < 40:
        u_wife_single[5] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep, p.alpha0) +   \
        ((p.alpha11_w + p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure_part + p.alpha3_w_s * kids_utility_single_w_ep + \
        home_time_w_preg * 0.5 + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[5] = float('-inf')


    if wife.age< 30:
        u_wife_single[6] = school_utility_w  # in school-no leisure, no income, but utility from schooling+increase future value
    else:
        u_wife_single[6] = float('-inf')

    if wife.kids > 0 and wife.welfare_periods < 5:  # max number of periods on welfare is 5
        u_wife_single[7] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue_welfare, p.alpha0) + \
            ((p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure + \
            p.alpha3_w_s * kids_utility_single_w_ue_welfare + home_time_w + divorce_cost_w * wife.married
    else:
        u_wife_single[7] = float('-inf')

    if wife.kids > 0 and wife.welfare_periods < 5 and wife.age < 40:
        u_wife_single[8] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ue_welfare, p.alpha0) + \
                ((p.alpha11_w + p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure + \
                p.alpha3_w_s * kids_utility_single_w_ue_welfare + home_time_w_preg + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[8] = float('-inf')

    if wife.kids > 0 and wife.welfare_periods < 5:  # max number of periods on welfare is 5
        u_wife_single[9] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef_welfare, p.alpha0) + \
                p.alpha3_w_s * kids_utility_single_w_ef_welfare + divorce_cost_w * wife.married
    else:
        u_wife_single[9] = float('-inf')

    if wife.kids > 0 and wife.welfare_periods < 5 and wife.age < 40:
        u_wife_single[10] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ef_welfare, p.alpha0) + \
                    p.alpha3_w_s * kids_utility_single_w_ef_welfare + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[10] = float('-inf')
    if wife.kids > 0 and wife.welfare_periods < 5:  # max number of periods on welfare is 5
        u_wife_single[11] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep_welfare, p.alpha0) + \
        ((p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure_part + p.alpha3_w_s * kids_utility_single_w_ep_welfare + \
        home_time_w * 0.5 + divorce_cost_w * wife.married
    else:
        u_wife_single[11] = float('-inf')

    if wife.kids > 0 and wife.welfare_periods < 5 and wife.age < 40:
        u_wife_single[12] = (1 / p.alpha0) * cmath.pow(budget_c_single_w_ep_welfare, p.alpha0) + \
        ((p.alpha11_w + p.alpha12_w * wife.schooling + p.alpha13_w * wife.health) / p.alpha2) * utility_leisure_part + p.alpha3_w_s * kids_utility_single_w_ep_welfare + \
        home_time_w_preg * 0.5 + preg_utility_um + divorce_cost_w * wife.married
    else:
        u_wife_single[12] = float('-inf')

    # calculate expected utility = current utility + emax value if t<T. = current utility + terminal value if t==T
    if t == c.max_period - 1:
        u_wife[0]= u_wife_single[0] + p.t1_w*wife.hsg+p.t2_w*wife.sc+p.t3_w*wife.cg+p.t4_w*wife.pc+p.t5_w*wife.exp
        u_wife[1]= float('-inf') # can't get pregnant at 60
        u_wife[2]= u_wife_single[2] + p.t1_w*wife.hsg+p.t2_w*wife.sc+p.t3_w*wife.cg+p.t4_w*wife.pc+p.t5_w*(wife.exp+1) #one more year of experience
        u_wife[3]= float('-inf') # can't get pregnant at 60
        u_wife[4]= u_wife_single[4] + p.t1_w*wife.hsg+p.t2_w*wife.sc+p.t3_w*wife.cg+p.t4_w*wife.pc+p.t5_w*(wife.exp+0.5) #one more year of experience
        u_wife[5] = float('-inf') # can't get pregnant at 60
        u_wife[6] = float('-inf') # can't go to school at 60
        if wife.kids > 0 and wife.welfare_periods < 5:  # max number of periods on welfare is 5
            u_wife[7]= u_wife_single[7] + p.t1_w*wife.hsg+p.t2_w*wife.sc+p.t3_w*wife.cg+p.t4_w*wife.pc+p.t5_w*wife.exp
            u_wife[9] = u_wife_single[9] + p.t1_w * wife.hsg + p.t2_w * wife.sc + p.t3_w * wife.cg + p.t4_w * wife.pc + p.t5_w * (wife.exp + 1)  #one more year of experience
            u_wife[11] = u_wife_single[11] + p.t1_w * wife.hsg + p.t2_w * wife.sc + p.t3_w * wife.cg + p.t4_w * wife.pc + p.t5_w * (wife.exp + 0.5)  #one more year of experience
        else:
            u_wife[7] = float('-inf')
            u_wife[9] = float('-inf')  # can't get pregnant at 60
            u_wife[11] = float('-inf')
        u_wife[8]= float('-inf') # can't get pregnant at 60
        u_wife[10] = float('-inf')
        u_wife[12] = float('-inf')

    #####################################################################   ADD EMAX    ########################
    # t - time 17-65
    # schooling - 5 levels grid
    # experience - 5 level grid
    # number of children - 4 level grid - 0, 1, 2 , 3+
    # health - 2 level grid
    # home time ar process - 3 level grid
    # ability_index - 3 level grid
    # parents education - 2 levels grid
    # parents marital status - 2 levels
    # EMAX_M_UM(t,wife.schooling, wife_exp_index,wife.kids, wife.health, wife_home_time_index,wife_ability_i, wife.mother_educ, wife.mother_marital)
    # need to take care of experience and number of children when calling the EMAX:
    # if women is pregnant, add 1 to the number of children unless the number is already 4
    elif t < c.max_period - 1:
        wife_exp_index = exp_to_index(wife.exp)
        wife_exp_index_f = exp_to_index(wife.exp + 1)  # increase experience by 1 if full time job
        wife_exp_index_p = exp_to_index(wife.exp + 0.5)  # increase experience by 0.5 if part-time job
        wife_ability_index = ability_to_index(wife.ability_i)
        wife_mother_educ_index = wife.mother_educ
        wife_mother_marital_index = wife.mother_marital
        wife_home_time_index = c.home_production
        wife_home_time_index_preg = c.home_production

        u_wife[0] = u_wife_single[0] + c.beta0 *     w_s_emax[t+1, wife.schooling, wife_exp_index, wife.kids, wife.health, wife_home_time_index, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        if wife.age < 40 and wife.kids < 3:
            kids_index = wife.kids+1
            u_wife[1] = u_wife_single[1] + c.beta0     * w_s_emax[t+1,wife.schooling, wife_exp_index, kids_index, wife.health, wife_home_time_index_preg,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[1] = float('-inf')

        u_wife[2] = u_wife_single[2] + c.beta0 * w_s_emax[t+1, wife.schooling, wife_exp_index_f,wife.kids, wife.health, wife_home_time_index,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        if  wife.age < 40 and wife.kids < 3:
            kids_index = wife.kids+1
            u_wife[3] = u_wife_single[3] + c.beta0 * w_s_emax[t+1, wife.schooling, wife_exp_index_f,kids_index, wife.health, wife_home_time_index_preg,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[3] = float('-inf')
        u_wife[4] = u_wife_single[4] + c.beta0 * w_s_emax[t+1, wife.schooling, wife_exp_index_p, wife.kids, wife.health, wife_home_time_index,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        if wife.age < 40 and wife.kids < 3:
            kids_index =  wife.kids+1
            u_wife[5] = u_wife_single[5] + c.beta0 * w_s_emax[t+1, wife.schooling, wife_exp_index_p, kids_index, wife.health, wife_home_time_index_preg,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[5] = float('-inf')
        if wife.age < 30 and wife.schooling  < 4:
            school_index = min(wife.schooling+1, 4)
            u_wife[6] = u_wife_single[6] + c.beta0 * w_s_emax[t+1, school_index, wife_exp_index,wife.kids, wife.health, wife_home_time_index,wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[6] = float('-inf')

        if wife.age > 20 and wife.age < 30 and wife.schooling  < 2:
            u_wife[6] = float('-inf')

        if wife.age > 19 and wife.age < 30 and wife.schooling  == 0:
            u_wife[6] = float('-inf')

        if wife.kids > 0 and wife.welfare_periods < 5:
            u_wife[7] = u_wife_single[7] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index, wife.kids, wife.health, wife_home_time_index, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[7] = float('-inf')
        if wife.age < 40 and wife.kids > 0 and wife.welfare_periods < 5 and wife.kids < 3:
            kids_index = wife.kids+1
            u_wife[8] = u_wife_single[8] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index, kids_index, wife.health, wife_home_time_index_preg, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[8] = float('-inf')
        if wife.kids > 0 and wife.welfare_periods < 5:
            u_wife[9] = u_wife_single[9] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index_f, wife.kids, wife.health, wife_home_time_index, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[9] = float('-inf')  # can't get pregnant after 40
        if wife.age < 40 and wife.kids > 0 and wife.welfare_periods < 5 and wife.kids <3:
            kids_index = wife.kids+1
            u_wife[10] = u_wife_single[10] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index_f, kids_index, wife.health, wife_home_time_index_preg, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[10] = float('-inf')
        if wife.kids > 0 and wife.welfare_periods < 5:
            u_wife[11] = u_wife_single[11] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index_p, wife.kids, wife.health, wife_home_time_index, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[11] = float('-inf')
        if wife.age < 40 and wife.kids > 0 and wife.welfare_periods < 5 and wife.kids <3:
            kids_index = wife.kids+1
            u_wife[12] = u_wife_single[12] + c.beta0 * w_s_emax[t + 1, wife.schooling, wife_exp_index_p, kids_index, wife.health, wife_home_time_index_preg, wife_ability_index, wife_mother_educ_index, wife_mother_marital_index]
        else:
            u_wife[12] = float('-inf')
    else:
        assert False

    for i in range(0, 13):
        u_wife_full[i] = u_wife[i]

    if wife.age > 39 or wife.kids == 3:   # can't get pregnant after 40
        u_wife[1] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[5] = float('-inf')
    if wage_w_full == 0:
        u_wife[2] = float('-inf')
        u_wife[3] = float('-inf')
        u_wife[9] = float('-inf')
        u_wife[10] = float('-inf')
    if wage_w_part == 0:
        u_wife[4] = float('-inf')
        u_wife[5] = float('-inf')
        u_wife[11] = float('-inf')
        u_wife[12] = float('-inf')

    ###################################################################################
    single_index = argmax(u_wife, 13)
    single_value = u_wife[single_index]
    # single_women_pregnancy_index_array = [1, 3, 5, 8, 10, 12]
    if single_index==1 or single_index==3 or single_index==5 or single_index==8 or single_index==10 or single_index==12:
        ar = home_time_w_preg
    else:
        ar = home_time_w
    
    return single_value, single_index, ar
