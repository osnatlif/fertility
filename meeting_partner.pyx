from parameters import p

# probability of meeting a partner is given in quadratic form
# as a function of age:
# prob = omega5_w*age^2 + omega4_w*age + omega3
#
# omega5_w, omega4_w, omega3 are set directly in the cohort parameter file
# (e.g. parameters1960white.py)
#
# since the quadratic form does not guarantee probability in the range [0, 1]
# this is enforced in the function

cpdef double prob(double age):
    if age < 20:
        return 0.02  # very low meeting probability at ages 18-19 (only HS women are active)
    prob = p.omega5_w*age*age + p.omega4_w*age + p.omega3
    if prob > 1:
        return 1
    if prob < 0.01:
        return 0.01
    return prob
