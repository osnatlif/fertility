# marriage market parameters
omega1 = -1.985          # probability of meeting a husband if below 18
omega2 = -0.9883         # probability of meeting a husband if in school

omega_max_prob = 0.51  # maximum probability
omega_age_max = 18     # age at maximum probability
omega_age_zero = 36    # age at zero probability

# these values are calculated "meeting_partner.pyx"
omega5_w = 0  # women's age*age
omega4_w = 0  # women's age
omega3   = 0  # probability of meeting a husband if above 18 not in school

omega4_h = omega4_w     # men's age
omega5_h = omega5_w     # men's age*age
omega6_w = 1.67         # women's probability of meeting a  CG - CONSTANT
omega7_w = -1.257       # women's women's probability of meeting a  CG if she SC
omega8_w = -4.054       # women's probability of meeting a  CG if she HS
omega9_w = 0.684        # women's probability of meeting a  SC - CONSTANT
omega10_w = -1.989      # women's probability of meeting a  SC if she HS
omega6_h = omega6_w     #1.358    # men's probability of meeting a  CG - CONSTANT
omega7_h = omega7_w     #-1.053   # men's probability of meeting a  CG if he SC
omega8_h = omega8_w     #-2.126   # men's probability of meeting a  CG if he HS
omega9_h = omega9_w     #0.265    # men's probability of meeting a  SC - CONSTANT
omega10_h = omega10_w   #-1.356  # men's probability of meeting a  SC if he HS
# wage parameters wife
beta0_w 	=	0.0351393	 #	ability
beta11_w	=	0.029424	#	experience	HSD
beta12_w	=	0.054481	#	experience	HSG
beta13_w	=	0.059876	#	experience	SC
beta14_w	=	0.073640	#	experience	CG
beta15_w	=	0.077927	#	experience	PC
beta21_w	=	-0.000515	#	exp^2	HSD
beta22_w	=	-0.001137	#	exp^2	HSG
beta23_w	=	-0.001301	#	exp^2	SC
beta24_w	=	-0.001591	#	exp^2	CG
beta25_w	=	-0.001668	#	exp^2	PC
beta31_w	=	9.656862	#	HSD
beta32_w	=	9.782523	#	HSG
beta33_w	=	9.973687	#	SC
beta34_w	=	10.294299	#	CG
beta35_w	=	10.474704	#	PC
#	wage	parameters	husband
beta0_h	    =	0.08174944	#	ability
beta11_h	=	0.044930	#	experience	HSD
beta12_h	=	0.072214	#	experience	HSG
beta13_h	=	0.081022	#	experience	SC
beta14_h	=	0.089615	#	experience	CG
beta15_h	=	0.099248	#	experience	PC
beta21_h	=	-0.000726	#	exp^2	HSD
beta22_h	=	-0.001349	#	exp^2	HSG
beta23_h	=	-0.001832	#	exp^2	SC
beta24_h	=	-0.001759	#	exp^2	CG
beta25_h	=	-0.001940	#	exp^2	PC
beta31_h	=	9.876768	#	hsd
beta32_h	=	9.938532	#	hsg
beta33_h	=	10.179946	#	sc
beta34_h	=	10.464128	#	cg
beta35_h	=	10.634752	#	pc
# job offer parameters - full time
lambda0_w_ft = -1.3199531085  # job offer parameters - wife - full time	constant
lambda1_w_ft = 0.03104	          # job offer parameters - wife	experience
lambda2_w_ft = 0.041191	      # job offer parameters - wife	education
lambda0_h_ft = 0.103328  	  # job offer parameters - husband - full Time	constant
lambda1_h_ft = 0.000210	      # job offer parameters - husband	experience
lambda2_h_ft = 0.00016	      # job offer parameters - husband	education
# job offer parameters - part-time
lambda0_w_pt = -2.2972	      # job offer parameters - wife - part-time	constant
lambda1_w_pt = 0.001	      # job offer parameters - wife	experience
lambda2_w_pt = 0.0024	      # job offer parameters - wife	education
lambda0_h_pt = -3.193	      # job offer parameters - husband  - part-time	constant
lambda1_h_pt = 0.011203	      # job offer parameters - husband	experience
lambda2_h_pt = 0.0002	      # job offer parameters - husband	education
# not get fired
lambda0_w_f = 1.25289	    # job offer parameters - wife - not fired  ( PT FT)	constant
lambda1_w_f = 0.049	        # job offer parameters - wife	experience
lambda2_w_f = 0.18	        # job offer parameters - wife	education
lambda0_h_f = 1.291	        # job offer parameters - husband - not fired (PT FT)	constant
lambda1_h_f = 0.057	        # job offer parameters - husband	experience
lambda2_h_f = 0.19	        # job offer parameters - husband	education
