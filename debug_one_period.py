import sys
print("start", flush=True)
import cohorts; cohorts.cohort = "1960white"
print("cohort set", flush=True)
import constant_parameters as c
print("c loaded emp_size_f=", c.emp_size_f, flush=True)
from calculate_emax import create_married_emax, create_single_w_emax, create_single_h_emax
from single_men import single_men
from single_women import single_women
from married_couple_emax import married_couple_emax
print("modules loaded", flush=True)
w_emax = create_married_emax()
h_emax = create_married_emax()
w_s_emax = create_single_w_emax()
h_s_emax = create_single_h_emax()
print("arrays created", flush=True)

t = c.max_period_f - 1
print(f"calling single_men(t={t})...", flush=True)
iter_count = single_men(t, w_emax, h_emax, w_s_emax, h_s_emax, False)
print(f"single_men done iter_count={iter_count}", flush=True)

print(f"calling single_women(t={t})...", flush=True)
iter_count = single_women(t, w_emax, h_emax, w_s_emax, h_s_emax, False)
print(f"single_women done iter_count={iter_count}", flush=True)

print(f"calling married_couple_emax(t={t})...", flush=True)
iter_count = married_couple_emax(t, w_emax, h_emax, w_s_emax, h_s_emax, False)
print(f"married done iter_count={iter_count}", flush=True)
