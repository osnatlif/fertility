import sys
print("step 1: start", flush=True)
import cohorts
cohorts.cohort = "1960white"
print("step 2: cohorts set", flush=True)
import constant_parameters as c
print("step 3: constant_parameters loaded, emp_size_f=", c.emp_size_f, flush=True)
from calculate_emax import create_married_emax, create_single_w_emax, create_single_h_emax, calculate_emax
print("step 4: calculate_emax module loaded", flush=True)
w_emax = create_married_emax()
print("step 5: w_emax shape=", w_emax.shape, flush=True)
h_emax = create_married_emax()
w_s_emax = create_single_w_emax()
h_s_emax = create_single_h_emax()
print("step 6: all arrays created", flush=True)
print("step 7: calling calculate_emax (will take a while)...", flush=True)
iter_count = calculate_emax(w_emax, h_emax, w_s_emax, h_s_emax, False)
print("step 8: done, iter_count=", iter_count, flush=True)
