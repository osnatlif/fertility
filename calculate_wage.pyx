cimport constant_parameters as c
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
from parameters import p
from draw_husband cimport Husband
from draw_wife cimport Wife


cpdef tuple calculate_wage_w(Wife wife):
    # this function calculates wives actual wage
    cdef double wage_full = 0
    cdef double wage_part = 0
    cdef double prob_full_tmp
    cdef double prob_part_tmp
    cdef double prob_full_w
    cdef double prob_part_w
    cdef double tmp1 = 0
    cdef double tmp2 = 0
    cdef double prob_not_laid_off_tmp
    cdef double prob_not_laid_off_w
    cdef int full_time_offer = 0
    cdef int part_time_offer = 0
    tmp_full = p.beta0_w * wife.ability_value + \
           p.beta11_w * wife.exp * wife.hsd + \
           p.beta12_w * wife.exp * wife.hsg + \
           p.beta13_w * wife.exp * wife.sc + \
           p.beta14_w * wife.exp * wife.cg + \
           p.beta15_w * wife.exp * wife.pc + \
           p.beta21_w * wife.exp_2 * wife.hsd + \
           p.beta22_w * wife.exp_2 * wife.hsg + \
           p.beta23_w * wife.exp_2 * wife.sc + \
           p.beta24_w * wife.exp_2 * wife.cg + \
           p.beta25_w * wife.exp_2 * wife.pc + \
           p.beta31_w * wife.hsd + p.beta32_w * wife.hsg + p.beta33_w * wife.sc + p.beta34_w * wife.cg + p.beta35_w * wife.pc

    prob_full_tmp = p.lambda0_w_ft + p.lambda1_w_ft * wife.exp + p.lambda2_w_ft * wife.schooling
    prob_part_tmp = p.lambda0_w_pt + p.lambda1_w_pt * wife.exp + p.lambda2_w_pt * wife.schooling
    prob_full_w = cmath.exp(prob_full_tmp) / (1 + cmath.exp(prob_full_tmp))
    prob_part_w = cmath.exp(prob_part_tmp) / (1 + cmath.exp(prob_part_tmp))

    if wife.emp == c.UNEMP:   # didn't work in previous period
        # draw job offer
        if uniform() < prob_full_w:   # got full time job offer - draw wage for full time
            full_time_offer = 1
        if uniform() < prob_part_w:
            part_time_offer = 1
        if full_time_offer or part_time_offer:
            if full_time_offer:
                tmp2 = randn(0, p.sigma_w_wage)
                wage_full = cmath.exp(tmp_full + tmp2)
            if part_time_offer:
                # draw wage for full time - will be multiply by 0.5 if part time job
                tmp2 = randn(0, p.sigma_w_wage)
                wage_part = 0.5 * cmath.exp(tmp_full + tmp2)
    else:   #    wife.emp == c.EMP - worked in previous period
        prob_not_laid_off_tmp = p.lambda0_w_f + p.lambda1_w_f*wife.exp + p.lambda2_w_f*wife.schooling
        prob_not_laid_off_w = cmath.exp(prob_not_laid_off_tmp)/(1+ cmath.exp(prob_not_laid_off_tmp))
        if uniform()  < prob_not_laid_off_w:
            tmp2 = randn(0, p.sigma_w_wage)
            if wife.capacity == 1:  # worked in previous period full time
                wage_full = cmath.exp(tmp_full + tmp2)
            else:
                assert(wife.capacity == 0.5)
                wage_part = 0.5 * cmath.exp(tmp_full + tmp2)

    return wage_full, wage_part,prob_full_w, prob_part_w, cmath.exp(tmp_full)

##############################################################################333
cpdef tuple calculate_wage_h(Husband husband):
    # this function calculates wives actual wage
    cdef double wage_full = 0
    cdef double wage_part = 0
    cdef double prob_full_tmp = 0
    cdef double prob_part_tmp = 0
    cdef double prob_full_h = 0
    cdef double prob_part_h = 0
    cdef double temp1 = 0
    cdef double temp2 = 0
    cdef double temp = 0
    cdef double tmp_full = 0
    cdef double tmp_part = 0
    cdef double prob_not_laid_off_tmp = 0
    cdef double prob_not_laid_off_w = 0
    tmp_full = p.beta0_h * husband.ability_value + \
               p.beta11_h * husband.exp * husband.hsd + \
               p.beta12_h * husband.exp * husband.hsg + \
               p.beta13_h * husband.exp * husband.sc + \
               p.beta14_h * husband.exp * husband.cg + \
               p.beta15_h * husband.exp * husband.pc + \
               p.beta21_h * cmath.pow(husband.exp * husband.hsd, 2) + \
               p.beta22_h * cmath.pow(husband.exp * husband.hsg, 2) + \
               p.beta23_h * cmath.pow(husband.exp * husband.sc, 2) + \
               p.beta24_h * cmath.pow(husband.exp * husband.cg, 2) + \
               p.beta25_h * cmath.pow(husband.exp * husband.pc, 2) + \
               p.beta31_h * husband.hsd + p.beta32_h * husband.hsg + p.beta33_h * husband.sc + p.beta34_h * husband.cg + p.beta35_h * husband.pc
    prob_full_tmp = p.lambda0_h_ft + p.lambda1_h_ft * husband.exp + p.lambda2_h_ft * husband.schooling
    prob_part_tmp = p.lambda0_h_pt + p.lambda1_h_pt * husband.exp + p.lambda2_h_pt * husband.schooling
    prob_full_h = cmath.exp(prob_full_tmp) / (1 + cmath.exp(prob_full_tmp))
    prob_part_h = cmath.exp(prob_part_tmp) / (1 + cmath.exp(prob_part_tmp))

    if husband.emp == c.UNEMP:  # didn't work in previous period
        # draw job offer
        temp = uniform()
        if temp  < prob_full_h:  # w_draws = rand(DRAW_F,T,2)  1 - health,2 -job offer,
            # draw wage for full time
            tmp2 = randn(0, p.sigma_h_wage)
            wage_full = cmath.exp(tmp_full + tmp2)
        if uniform()  < prob_part_h:
            tmp2 = randn(0, p.sigma_h_wage)
            wage_part = 0.5 * cmath.exp(tmp_full + tmp2)
    else:  #  husband.emp == 1 - worked in previous period
        prob_not_laid_off_tmp = p.lambda0_h_f + p.lambda1_h_f * husband.exp + p.lambda2_h_f *  husband.schooling
        prob_not_laid_off_h = cmath.exp(prob_not_laid_off_tmp) / (1 + cmath.exp(prob_not_laid_off_tmp))
        if uniform() < prob_not_laid_off_h:
            tmp2 = randn(0, p.sigma_h_wage)
            if husband.capacity == 1:  # worked in previous period full time
                wage_full = cmath.exp(tmp_full + tmp2)
            else:
                assert(husband.capacity == 0.5)
                wage_part = 0.5 * cmath.exp(tmp_full + tmp2)
    return wage_full, wage_part, prob_full_h, prob_part_h, cmath.exp(tmp_full)
