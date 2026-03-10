from parameters import p

# probability of meeting a partner is given in quadratic form
# as a function of age:
# prob = omega5_w*age^2 + omega4_w*age + omega3
#
# the quadratic parameters are calculated based on:
# * the maximum probability value: omega_max_prob
# * the age in which this maximum is reached: omega_age_max
# * the age in which the probability reaches zero: omega_age_zero
#
# since the quadratic form does not guarantee probability in the range [0, 1]
# this is enforced in the function

omega_age_max_2 = p.omega_age_max*p.omega_age_max
omega_age_zero_2 = p.omega_age_zero*p.omega_age_zero

p.omega5_w = -p.omega_max_prob/(omega_age_zero_2 - 2*p.omega_age_max*p.omega_age_zero + omega_age_max_2)
p.omega4_w = -2*p.omega5_w*p.omega_age_max
p.omega3   = p.omega_max_prob + p.omega5_w*omega_age_max_2

cpdef double prob(double age):
    prob = p.omega5_w*age*age + p.omega4_w*age + p.omega3
    if prob > 1:
        return 1
    if prob < 0.01:
        return 0.01
    return prob


#import matplotlib.pyplot as plt
#ages = [float(i/100) for i in range(1000, 5000)]
#probs = [prob(age) for age in ages]
#plt.plot(ages, probs)
#plt.show()
