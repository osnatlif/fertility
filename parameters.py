import importlib
import cohorts
import numpy as np

##############################################################################
# per cohort parameters
##############################################################################
p = importlib.import_module("input.parameters"+str(cohorts.cohort))

##############################################################################
# fixed parameters
##############################################################################
p.taste_c = 160.36           # taste for marriage	constant
p.taste_w_up = -12.894  	 # taste for marriage	schooling gap - men more educated
p.taste_w_down = -10.227	 # taste for marriage	schooling gap - women more educated
p.taste_health = 0           # taste for marriage	health gap
p.preg_const = -101.0002     # utility from pregnancy -
p.preg_unmarried = -1099.429 # utility from pregnancy -	unmarried
p.preg_t_minus1 = -400.227   # utility from pregnancy - pregnancy in t-1
p.preg_kids = -10.98         # utility from pregnancy - number of kids
p.health = -11.35753         # utility from pregnancy - age
# utility from quality and quantity of children
p.row0 = 0.869	             # utility from quality and quantity of children	CES function's parameter
p.row1_w = 0.546	         # utility from quality and quantity of children	wife leisure
p.row1_h = 0.450	         # utility from quality and quantity of children	husband leisure
p.row2 = 3.199585	         # utility from quality and quantity of children	number of children
# welfare parameters
p.stigma = -10.742	         # disutility from welfare
p.stigma96 = -8791.543	     # disutility from welfare after 1996
p.p_alimony = np.exp(-0.783)/(1+np.exp(-0.783))	    # prob of having alimony for single mothers)
p.alimony = np.exp(11.689)	 # mean of alimony	exp of draw from normal distribution
# utility parameters
p.alpha0 = 0.541            # utility parameters 	CRRA consumption parameter
p.alpha11_w = 0.402	        # utility parameters - wife	leisure when pregnant
p.alpha12_w = 0.078	        # utility parameters - wife	leisure by  education
p.alpha13_w = 0.157	        # utility parameters - wife	leisure by health
p.alpha12_h = 0.06          # utility parameters -husband	leisure by  education
p.alpha13_h = 0.1058	    # utility parameters -husband	leisure by health
p.alpha2 = 0.751	        # utility parameters 	utility from leisure CRRA parameter
p.alpha3_w_m = 0.2519122    # utility parameters - wife	utility from kids when married
p.alpha3_w_s = 0.0002172464	# utility parameters - wife	utility from kids when single
p.alpha3_h_m = 0.2519126	# utility parameters - husband	utility from kids when married
p.alpha3_h_s = 0.00168	    # utility parameters - husband	utility from kids when single
# marriage and divorce cost
p.mc = -30.946	             # fixed cost of getting married
p.mc_by_parents = -4422.691	 # cost of marriage by parents marital status
p.dc_w = -30.579	         # fixed cost of divorce wife	alpha4
p.dc_h = -30.691	         # fixed cost of divorce husband	alpha4
p.dc_w_kids = -210.372	     # fixed cost of divorce child wife	alpha4
p.dc_h_kids = -210.260	     # fixed cost of divorce child husband	alpha4
p.tau0_w = 0.0	             # Home Time Equation - wife	constant
p.tau1_w = 0.842	         # home time equation - wife	ar coefficient
p.tau2_w = 2.2593	         # home time equation - wife	pregnancy in previous period
p.tau0_h = 0.0	             # home time equation - husband	constant
p.tau1_h = 0.691	         # home time equation - husband	ar coefficient
p.tau2_h = 0.454	         # home time equation - husband	pregnancy in previous period
#  ability parameters
p.ab_high1 = -0.918	         # ability parameters - high	ability constant
p.ab_high2 = 1.58211 	     # ability parameters - high	ability parents education
p.ab_high3 = 1.09413	     # ability parameters - high	ability parents married
p.ab_medium1 = -0.261460	 # ability parameters - medium	ability constant
p.ab_medium2 = 0.999	     # ability parameters - medium	ability parents education
p.ab_medium3 = 0.872	     # ability parameters - medium	ability parents married
# error terms variance
p.sigma_ability_w = np.exp(0.12549)	  # random shock variance matrix	variance wife ability
p.sigma_ability_h = np.exp(0.171592)  # random shock variance matrix	variance husband ability
p.sigma_hp_w = np.exp(-0.426) 	      # random shock variance matrix	variance home time wife
p.sigma_hp_h = np.exp(-0.312)	      # random shock variance matrix	variance home time husband
p.sigma_w_wage = np.exp(-1.0620) 	  # random shock variance matrix	wife's wage error variance
p.sigma_h_wage = np.exp(-1.0624) 	  # random shock variance matrix	husband's wage error variance
p.sigma_q = np.exp(1.98422)	          # random shock variance matrix	match quality variance
p.sigma_q_p = np.exp(1.98422)	      # random shock variance matrix	match quality variance
p.sigma_p = np.exp(4.8225)	          # random shock variance matrix	pregnancy
# utility from schooling parameters
p.s1_w = -280.432	   # utility from schooling - wife	s1_w constant
p.s2_w = 275.469	   # utility from schooling - wife	s2_w mother is CG
p.s3_w = 245.674	   # utility from schooling - wife	s3_w return for ability
p.s4_w = -715.429	   # utility from schooling - wife+husband	s4_w post high school tuition
p.s1_h = -990.375	   # utility from schooling - husband	s1_h constant
p.s2_h = 266.582	   # utility from schooling - husband	s2_h mother is  CG
p.s3_h = 840.719	   # utility from schooling - husband	s3_h return for ability
# terminal value parameters
p.t1_w = 10.918	    # terminal value - wife:	wife Education - HSG
p.t2_w = 20.462	    # terminal value - wife:	wife Education - SC
p.t3_w = 30.885	    # terminal value - wife:	wife Education - CG
p.t4_w = 32.247	    # terminal value - wife:	wife Education - PC
p.t5_w = 121.278	# terminal value - wife:	wife experience
p.t6_w = 8.210 	    # terminal value - wife: husband education - HSG
p.t7_w = 19.216	    # terminal value - wife:	husband education - SC
p.t8_w = 23.130	    # terminal value - wife:	husband education - CG
p.t9_w = 51.873	    # terminal value - wife:	husband education - PC
p.t10_w = 116.833	# terminal value - wife:	husband experience
p.t11_w = 712.743	# terminal value - wife:	marriage utility
p.t12_w = 100.3757  # terminal value - wife: children
p.t1_h = 10.942	    # terminal value - husband: wife Education - HSG
p.t2_h = 20.655	    # terminal value - husband: wife Education - SC
p.t3_h = 30.843	    # terminal value - husband: wife Education - CG
p.t4_h = 40.215	    # terminal value - husband: wife Education - PC
p.t5_h = 115.222	# terminal value - husband: wife	experience
p.t6_h = 7.880	    # terminal value - husband: husband education - HSG
p.t7_h = 19.516	    # terminal value - husband: husband education - SC
p.t8_h = 33.348	    # terminal value - husband: husband education - CG
p.t9_h = 41.876	    # terminal value - husband: husband education - PC
p.t10_h = 117.660	# terminal value - husband: husband experience
p.t11_h = 670.536	# terminal value - husband: marriage utility
p.t12_h = 100.3757  # terminal value - husband: children