import importlib
import cohorts
import numpy as np

##############################################################################
# per cohort parameters
##############################################################################
p = importlib.import_module("input.parameters"+str(cohorts.cohort))

##############################################################################
# fixed parameters - ~41 + 18 emp +5 marriage
##############################################################################
p.mconst = 100.0
p.taste_cg = 360.0        # taste for homogenous marriage	CG
p.taste_sc = 250.0    	 # taste for mhomogenous marriage	SC
p.taste_hs = -110.0    	 # taste for mhomogenous marriage	HS
p.preg_married = 0      # utility from pregnancy
p.preg_unmarried = 0   # utility from pregnancy -	unmarried
p.preg_kids = 0         # utility from pregnancy - number of kids
# utility from quality and quantity of children
# utility parameters
p.alpha0 = 0.541            # utility parameters - CRRA consumption parameter
p.alpha2w0 = 0.8            # utility parameters - wife leisure constant (raised to reduce FT)
p.alpha2w1 = -0.15          # utility parameters - wife leisure * kids
p.alpha2h0 = 0.5            # utility parameters - husband leisure constant
p.alpha2h1 = -0.1           # utility parameters - husband leisure * kids
p.alpha3_w_m = 60.0         # utility parameters - wife	utility from kids when married
p.alpha3_w_s = 21.0          # utility parameters - wife	utility from kids when single
p.alpha3_h_m = 80.0        	# utility parameters - husband	utility from kids when married
p.alpha3_h_s = 1.0          # utility parameters - husband	utility from kids when single
p.alpha4 = 0.65 	            # utility from children

# marriage and divorce cost
p.mc = 0.0	             # fixed cost of getting married
p.dc_w = -150.0  	         # fixed cost of divorce wife
p.dc_h = -150.0  	         # fixed cost of divorce husband
p.dc_w_kids = -250.0	     # fixed cost of divorce child wife
p.dc_h_kids = -250.0	     # fixed cost of divorce child husband
#  ability parameters
p.ab_high = -0.918	         # ability parameters - high	ability constant
p.ab_medium = -0.261460	 # ability parameters - medium	ability constant
# error terms variance
p.sigma_ability_w = np.exp(-0.12549)	  # random shock variance wife ability
p.sigma_ability_h = np.exp(-0.171592)  # random shock variance husband ability
p.sigma_w_wage = np.exp(-1.0620) 	  # random shock wife's wage error variance
p.sigma_h_wage = np.exp(-1.0624) 	  # random shock husband's wage error variance
p.sigma_q = np.exp(-0.598422)	          # random shock match quality variance
p.sigma_p = np.exp(-0.59)  	          # random shock pregnancy
# terminal value parameters
p.t1_w = 20.462	    # terminal value - wife:	wife Education - SC
p.t2_w = 30.885	    # terminal value - wife:	wife Education - CG+
p.t3_w = 19.216	    # terminal value - wife:	husband education - SC
p.t4_w = 23.130	    # terminal value - wife:	husband education - CG+
p.t5_w = 500.0  	# terminal value - wife:	marriage utility
p.t6_w = 750.0      # terminal value - wife: children
p.t1_h = 20.655	    # terminal value - husband: wife Education - SC
p.t2_h = 30.843	    # terminal value - husband: wife Education - CG+
p.t3_h = 19.516	    # terminal value - husband: husband education - SC
p.t4_h = 33.348	    # terminal value - husband: husband education - CG+
p.t5_h = 450.0  	# terminal value - husband: marriage utility
p.t6_h = 700.0      # terminal value - husband: children
