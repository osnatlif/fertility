# 18 parameters of employment + 5 parameters for marriage offer
# meeting probability: prob = omega5_w*age^2 + omega4_w*age + omega3
# curve: ~0.05 at 18, peak ~0.35 at 30-32, ~0 at 48
omega5_w = -0.001481  # women's age*age
omega4_w = 0.096111   # women's age
omega3   = -1.200000  # constant
omega4_h = omega4_w     # men's age
omega5_h = omega5_w     # men's age*age
# wage parameters wife - calibrated to match actual wage moments
beta0_w  =  0.10   # ability - increased for meaningful selection
beta11_w    =  0.0394   #  t= experience  HS (was 0.0378)
beta12_w    =  0.0615  #  t = experience SC (was 0.0594)
beta13_w    =  0.075 #  t = experience CG+ (was 0.048613)
beta21_w    =  -0.00063  #  t^2 = exp^2    HS
beta22_w    =  -0.00122  #  t^2 = exp^2    SC
beta23_w    =  -0.00092  #  t^2 = exp^2    CG+
beta31_w    =  10.0379 #  HS (was 9.7722)
beta32_w    =  10.18   #  SC (was 9.9029)
beta33_w    =  10.55  #  CG+ (was 10.3961)
beta41_w	=	-0.3 	#	not employed in previous period * HS
beta42_w	=	-0.4	#	not employed in previous period * SC
beta43_w	=	-0.7	#	not employed in previous period * CG+
#	wage	parameters	husband - calibrated to match actual wage moments
beta0_h	    =	0.15	#	ability
beta11_h    =  0.0612   #  experience HS (was 0.0631)
beta12_h    =  0.0937   #  experience SC (was 0.0883)
beta13_h    =  0.1141   #  experience CG+ (was 0.0946)
beta21_h    =  -0.00126  #  exp^2  HS
beta22_h    =  -0.002 #  exp^2  SC
beta23_h    =  -0.00198  #  exp^2  CG+
beta31_h    =  10.30   #  HS
beta32_h    =  10.29   #  SC
beta33_h    =  10.35  #  CG+
beta41_h	=	-0.5	#	not employed in previous period * HS
beta42_h	=	-0.5	#	not employed in previous period * SC
beta43_h	=	-0.7	#	not employed in previous period * CG+
# job offer parameters - full time: prob = logistic(lambda0 + lambda1*t + lambda15*t^2 + lambda2*schooling)
lambda0_w_ft = -1.3199531085  # job offer parameters - wife - full time	constant
lambda1_w_ft = 0.03104	          # job offer parameters - wife	experience
lambda15_w_ft = 0.0	          # job offer parameters - wife	experience^2
lambda2_w_ft = 0.30	      # job offer parameters - wife	education
lambda0_h_ft = -0.30  	      # job offer parameters - husband - full Time	constant (was 0.103)
lambda1_h_ft = 0.06	          # job offer parameters - husband	experience (was 0.00021)
lambda15_h_ft = -0.0015	      # job offer parameters - husband	experience^2
lambda2_h_ft = 0.00016	      # job offer parameters - husband	education
# job offer parameters - part-time: prob = logistic(lambda0 + lambda1*t + lambda15*t^2 + lambda2*schooling)
lambda0_w_pt = -2.2972	      # job offer parameters - wife - part-time	constant
lambda1_w_pt = 0.001	      # job offer parameters - wife	experience
lambda15_w_pt = 0.0	      # job offer parameters - wife	experience^2
lambda2_w_pt = 0.0024	      # job offer parameters - wife	education
lambda0_h_pt = -3.193	      # job offer parameters - husband  - part-time	constant
lambda1_h_pt = 0.011203	      # job offer parameters - husband	experience
lambda15_h_pt = 0.0	      # job offer parameters - husband	experience^2
lambda2_h_pt = 0.0002	      # job offer parameters - husband	education
# not get fired: prob = logistic(lambda0 + lambda1*t + lambda15*t^2 + lambda2*schooling)
lambda0_w_f = 1.25289	    # job offer parameters - wife - not fired  ( PT FT)	constant
lambda1_w_f = 0.049	        # job offer parameters - wife	experience
lambda15_w_f = 0.0	        # job offer parameters - wife	experience^2
lambda2_w_f = 0.18	        # job offer parameters - wife	education
lambda0_h_f = 1.291	        # job offer parameters - husband - not fired (PT FT)	constant
lambda1_h_f = 0.057	        # job offer parameters - husband	experience
lambda15_h_f = 0.0	        # job offer parameters - husband	experience^2
lambda2_h_f = 0.19	        # job offer parameters - husband	education
