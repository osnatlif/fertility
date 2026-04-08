cimport constant_parameters as c
cimport libc.math as cmath
cdef extern from "randn.cc":
    double randn(double mu, double sigma)
    double uniform()
from parameters import p
from draw_husband cimport Husband
from draw_wife cimport Wife


cpdef tuple calculate_wage_w(Wife wife, int t):
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
           p.beta11_w * t * wife.hs + \
           p.beta12_w * t * wife.sc + \
           p.beta13_w * t * wife.cg + \
           p.beta21_w * t * t * wife.hs + \
           p.beta22_w * t * t * wife.sc + \
           p.beta23_w * t * t * wife.cg + \
           p.beta41_w * (1-wife.emp) * wife.hs + \
           p.beta42_w * (1-wife.emp) * wife.sc + \
           p.beta43_w * (1-wife.emp) * wife.cg + \
           p.beta31_w * wife.hs + p.beta32_w * wife.sc + p.beta33_w * wife.cg

    prob_full_tmp = p.lambda0_w_ft + p.lambda1_w_ft * t + p.lambda15_w_ft * t * t + p.lambda2_w_ft * wife.schooling
    prob_part_tmp = p.lambda0_w_pt + p.lambda1_w_pt * t + p.lambda15_w_pt * t * t + p.lambda2_w_pt * wife.schooling
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
        prob_not_laid_off_tmp = p.lambda0_w_f + p.lambda1_w_f*t + p.lambda15_w_f*t*t + p.lambda2_w_f*wife.schooling
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
cpdef tuple calculate_wage_h(Husband husband, int t):
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
               p.beta11_h * t * husband.hs + \
               p.beta12_h * t * husband.sc + \
               p.beta13_h * t * husband.cg + \
               p.beta21_h * t * t * husband.hs + \
               p.beta22_h * t * t * husband.sc + \
               p.beta23_h * t * t * husband.cg + \
               p.beta41_h * (1-husband.emp) * husband.hs + \
               p.beta42_h * (1-husband.emp) * husband.sc + \
               p.beta43_h * (1-husband.emp) * husband.cg + \
               p.beta31_h * husband.hs + p.beta32_h * husband.sc + p.beta33_h * husband.cg
    prob_full_tmp = p.lambda0_h_ft + p.lambda1_h_ft * t + p.lambda15_h_ft * t * t + p.lambda2_h_ft * husband.schooling
    prob_part_tmp = p.lambda0_h_pt + p.lambda1_h_pt * t + p.lambda15_h_pt * t * t + p.lambda2_h_pt * husband.schooling
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
        prob_not_laid_off_tmp = p.lambda0_h_f + p.lambda1_h_f * t + p.lambda15_h_f * t * t + p.lambda2_h_f *  husband.schooling
        prob_not_laid_off_h = cmath.exp(prob_not_laid_off_tmp) / (1 + cmath.exp(prob_not_laid_off_tmp))
        if uniform() < prob_not_laid_off_h:
            tmp2 = randn(0, p.sigma_h_wage)
            if husband.capacity == 1:  # worked in previous period full time
                wage_full = cmath.exp(tmp_full + tmp2)
            else:
                assert(husband.capacity == 0.5)
                wage_part = 0.5 * cmath.exp(tmp_full + tmp2)
    return wage_full, wage_part, prob_full_h, prob_part_h, cmath.exp(tmp_full)
