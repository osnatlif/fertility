"""Trace marriage decision utility components to understand why marriages form and dissolve."""
import numpy as np
import cohorts
cohorts.cohort = "1960white"
import constant_parameters as c
from parameters import p

w_emax = np.load("emax_1960white/w_emax.npy")
h_emax = np.load("emax_1960white/h_emax.npy")
w_s_emax = np.load("emax_1960white/w_s_emax.npy")
h_s_emax = np.load("emax_1960white/h_s_emax.npy")

print("=" * 80)
print("KEY PARAMETER VALUES")
print("=" * 80)
print(f"  taste_c (marriage constant)  = {p.taste_c:10.3f}")
print(f"  taste_w_up (h more educated) = {p.taste_w_up:10.3f}")
print(f"  taste_w_down (w more educ)   = {p.taste_w_down:10.3f}")
print(f"  mc (marriage cost)           = {p.mc:10.3f}")
print(f"  dc_w (divorce cost wife)     = {p.dc_w:10.3f}")
print(f"  dc_h (divorce cost husband)  = {p.dc_h:10.3f}")
print(f"  dc_w_kids (divorce cost/kid) = {p.dc_w_kids:10.3f}")
print(f"  dc_h_kids (divorce cost/kid) = {p.dc_h_kids:10.3f}")
print(f"  sigma_q (match quality shock) = {p.sigma_q:10.3f}  (exp(1.98))")
print(f"  match_vector = [-1.15, 0, 1.15]")
print(f"  alpha3_w_m (wife kids married) = {p.alpha3_w_m:10.6f}")
print(f"  alpha3_w_s (wife kids single)  = {p.alpha3_w_s:10.6f}")
print(f"  alpha3_h_m (husb kids married) = {p.alpha3_h_m:10.6f}")
print(f"  alpha3_h_s (husb kids single)  = {p.alpha3_h_s:10.6f}")
print(f"  beta0 (discount rate)        = {0.983}")
print(f"  t5_w (terminal marriage wife)  = {p.t5_w:10.3f}")
print(f"  t5_h (terminal marriage husb)  = {p.t5_h:10.3f}")

print()
print("=" * 80)
print("EMAX COMPARISON: MARRIED vs SINGLE by (wife_edu, husband_edu) combos")
print("  State: 0 kids, medium ability, kb5=0, we=0, he=0, mq=medium(1)")
print("=" * 80)

combos = [(0,0,"HS-HS"), (0,1,"HS-SC"), (0,2,"HS-CG"), (1,1,"SC-SC"), (2,2,"CG-CG")]
for sw, sh, label in combos:
    min_t = max(c.AGE_VALUES_f[sw] - 17, c.AGE_VALUES_f[sh] - 17)
    print(f"\n  {label}:")
    print(f"  {'t':>3} {'age':>4} {'w_married':>11} {'w_single':>11} {'diff_w':>9} {'h_married':>11} {'h_single':>11} {'diff_h':>9}")
    for t in range(min_t, 30):
        wm = w_emax[t, sw, sh, 0, 1, 1, 0, 0, 0, 1]
        ws = w_s_emax[t, sw, 0, 1, 0, 0]
        hm = h_emax[t, sw, sh, 0, 1, 1, 0, 0, 0, 1]
        hs_val = h_s_emax[t, sh, 0, 1, 0]
        dw = wm - ws if wm > -1e10 and ws > -1e10 else float('nan')
        dh = hm - hs_val if hm > -1e10 and hs_val > -1e10 else float('nan')
        print(f"  {t:3d} {17+t:4d} {wm:11.1f} {ws:11.1f} {dw:9.1f} {hm:11.1f} {hs_val:11.1f} {dh:9.1f}")

print()
print("=" * 80)
print("MARRIAGE UTILITY DECOMPOSITION (forward simulation, not married yet)")
print("  For an HS woman meeting HS husband, both medium ability, 0 kids")
print("  Option 8: wife full-time, husband full-time, no pregnancy")
print("=" * 80)

# Simulate the components for a specific decision
# Using simplified calculations (no job offer randomness)
import math

alpha0 = p.alpha0
scale = 0.707

print(f"\n  {'age':>4} {'taste':>8} {'mc_cost':>8} {'cons_m':>10} {'cons_s':>10} {'emax_m':>10} {'emax_s':>10} {'dc_cost':>8} {'total_m':>10} {'total_s':>10} {'m-s':>8}")

for age in range(18, 47):
    t = age - 17
    # Approximate wages using wage parameters (simplified)
    exp_w = t  # experience ~ period
    log_wage_w = p.beta31_w + p.beta0_w * 0 + p.beta11_w * exp_w + p.beta21_w * exp_w**2
    wage_w_full = math.exp(log_wage_w)
    log_wage_h = p.beta31_h + p.beta0_h * 0 + p.beta11_h * exp_w + p.beta21_h * exp_w**2
    wage_h_full = math.exp(log_wage_h)

    # Married income: wife FT + husband FT, 0 kids
    married_income = wage_w_full + wage_h_full  # simplified, no tax
    single_w_income = wage_w_full  # simplified

    # Consumption utility (CRRA)
    cons_married = (1/alpha0) * (married_income * scale) ** alpha0 if married_income > 0 else 0
    cons_single = (1/alpha0) * single_w_income ** alpha0 if single_w_income > 0 else 0

    # Marriage taste + match quality (medium = 0)
    taste = p.taste_c + 0  # match_quality = 0 for medium

    # Marriage cost (only if not yet married)
    mc_cost = p.mc  # -30.946

    # Divorce cost (only if already married choosing single)
    dc_cost = 0  # not married yet, so no divorce cost in single option

    # Emax
    if t < 39:
        emax_m_w = 0.983 * w_emax[t+1, 0, 0, 0, 1, 1, 0, 0, 0, 1] if w_emax[t+1, 0, 0, 0, 1, 1, 0, 0, 0, 1] > -1e10 else 0
        emax_s_w = 0.983 * w_s_emax[t+1, 0, 0, 1, 0, 0] if w_s_emax[t+1, 0, 0, 1, 0, 0] > -1e10 else 0
    else:
        emax_m_w = p.t5_w  # terminal married bonus
        emax_s_w = p.t1_w * 0 + p.t2_w * 0  # terminal single (HS)

    total_married = taste + cons_married + mc_cost + emax_m_w
    total_single = cons_single + emax_s_w + dc_cost

    print(f"  {age:4d} {taste:8.1f} {mc_cost:8.1f} {cons_married:10.1f} {cons_single:10.1f} "
          f"{emax_m_w:10.1f} {emax_s_w:10.1f} {dc_cost:8.1f} {total_married:10.1f} {total_single:10.1f} {total_married - total_single:8.1f}")


print()
print("=" * 80)
print("DIVORCE COST ANALYSIS")
print("  Divorce cost increases with kids, making divorce harder with kids")
print("=" * 80)
for kids in range(4):
    dc_w = p.dc_w + p.dc_w_kids * kids
    dc_h = p.dc_h + p.dc_h_kids * kids
    print(f"  {kids} kids: wife divorce cost = {dc_w:8.1f}, husband divorce cost = {dc_h:8.1f}")

print()
print("=" * 80)
print("ALREADY-MARRIED: CONTINUE vs DIVORCE (wife, HS-HS, medium MQ)")
print("  Already married with 2 kids")
print("=" * 80)
print(f"  {'age':>4} {'taste+mq':>10} {'emax_m':>10} {'emax_s':>10} {'emax_diff':>10} {'dc_2kids':>10} {'net_m-s':>10}")
dc_w_2kids = p.dc_w + p.dc_w_kids * 2  # divorce cost with 2 kids
for age in range(22, 47):
    t = age - 17
    if t < 39:
        emax_m_w = 0.983 * w_emax[t+1, 0, 0, 2, 1, 1, 0, 0, 0, 1]
        emax_s_w = 0.983 * w_s_emax[t+1, 0, 2, 1, 0, 0]
    else:
        emax_m_w = p.t5_w + p.t6_w  # terminal: married + kids
        emax_s_w = 0
    emax_diff = emax_m_w - emax_s_w
    taste_mq = p.taste_c + 0  # medium match quality = 0
    # net advantage: taste + emax_diff (from married being higher) - dc_cost (penalty for divorcing)
    # If net > 0, staying married is better
    # Note: dc is negative (penalty), so subtracting it ADDS to the single option's cost
    # The comparison is: married_util > single_util
    # married_util ≈ taste + cons_married + emax_married
    # single_util ≈ cons_single + emax_single + dc  (dc is negative, making single worse)
    # So advantage = taste + emax_diff - dc (because dc makes single worse)
    advantage = taste_mq + emax_diff - dc_w_2kids  # dc is negative, so minus negative = positive
    print(f"  {age:4d} {taste_mq:10.1f} {emax_m_w:10.1f} {emax_s_w:10.1f} {emax_diff:10.1f} {dc_w_2kids:10.1f} {advantage:10.1f}")
