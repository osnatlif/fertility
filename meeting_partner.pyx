from parameters import p

# Probability of meeting a partner, gender-specific age quadratic.
#   prob_w(age) = omega5_w*age^2 + omega4_w*age + omega3   (wife)
#   prob_h(age) = omega5_h*age^2 + omega4_h*age + omega3   (husband)
#
# omega5/4/3 are set in the cohort parameter file (e.g. parameters1960white.py).
# omega3 is a shared intercept; the age slopes are gender-specific (the husband
# pair is initialised equal to the wife pair in the cohort file, but they are
# independent parameters once setattr is used by the estimator).
#
# Since the quadratic does not guarantee a probability in [0,1], we clip.

cdef inline double _clip_prob(double v):
    if v > 1.0:
        return 1.0
    if v < 0.01:
        return 0.01
    return v

cpdef double prob_w(double age):
    if age < 20:
        return 0.02  # very low at 18-19 (only HS women are active)
    return _clip_prob(p.omega5_w*age*age + p.omega4_w*age + p.omega3)

cpdef double prob_h(double age):
    if age < 20:
        return 0.02
    return _clip_prob(p.omega5_h*age*age + p.omega4_h*age + p.omega3)
