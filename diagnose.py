"""Quick diagnostics for meeting probability, husband education draw, and emax sanity."""
import numpy as np
import cohorts
cohorts.cohort = "1960white"
import constant_parameters as c
from parameters import p

print("=" * 60)
print("1. MEETING PROBABILITY BY AGE")
print("=" * 60)
# reconstruct the quadratic from parameters
omega_age_max_2 = p.omega_age_max * p.omega_age_max
omega_age_zero_2 = p.omega_age_zero * p.omega_age_zero
omega5 = -p.omega_max_prob / (omega_age_zero_2 - 2*p.omega_age_max*p.omega_age_zero + omega_age_max_2)
omega4 = -2 * omega5 * p.omega_age_max
omega3 = p.omega_max_prob + omega5 * omega_age_max_2

print(f"  omega_max_prob={p.omega_max_prob}, omega_age_max={p.omega_age_max}, omega_age_zero={p.omega_age_zero}")
print(f"  quadratic: {omega5:.6f}*age^2 + {omega4:.6f}*age + {omega3:.6f}")
print(f"  {'age':>4} {'prob':>8}")
for age in range(18, 56):
    prob = omega5 * age * age + omega4 * age + omega3
    if prob > 1: prob = 1
    if prob < 0.01: prob = 0.01
    print(f"  {age:4d} {prob:8.4f}")

print()
print("=" * 60)
print("2. HUSBAND EDUCATION DISTRIBUTION (from input file)")
print("=" * 60)
edu_dist = np.loadtxt("input/education_dist_m1960white.txt")
print(f"  {'age':>4} {'P(HS)':>8} {'P(SC)':>8} {'P(CG)':>8}")
for row in edu_dist:
    print(f"  {int(row[0]):4d} {row[1]:8.3f} {row[2]:8.3f} {row[3]:8.3f}")

print()
print("=" * 60)
print("3. EMAX SAMPLE VALUES (married w_emax)")
print("=" * 60)
w_emax = np.load("emax_1960white/w_emax.npy")
h_emax = np.load("emax_1960white/h_emax.npy")
w_s_emax = np.load("emax_1960white/w_s_emax.npy")
h_s_emax = np.load("emax_1960white/h_s_emax.npy")

print(f"  w_emax shape: {w_emax.shape}")
print(f"  h_emax shape: {h_emax.shape}")
print(f"  w_s_emax shape: {w_s_emax.shape}")
print(f"  h_s_emax shape: {h_s_emax.shape}")

# Check a slice: t, school_w=0(HS), school_h=0(HS), kids=0, ability_w=1, ability_h=1, kb5=0, we=0, he=0, mq=1
print("\n  w_emax[t, HS, HS, 0kids, med_ab_w, med_ab_h, kb5=0, we=0, he=0, mq=med] by age:")
for t in range(1, 30):
    val = w_emax[t, 0, 0, 0, 1, 1, 0, 0, 0, 1]
    print(f"    t={t:2d} (age {17+t:2d}): {val:12.2f}")

print("\n  w_emax[t, SC, SC, ...] by age:")
for t in range(1, 30):
    val = w_emax[t, 1, 1, 0, 1, 1, 0, 0, 0, 1]
    age = 17 + t
    marker = " *" if age < 20 else ""
    print(f"    t={t:2d} (age {age:2d}): {val:12.2f}{marker}")

print("\n  w_emax[t, CG, CG, ...] by age:")
for t in range(1, 30):
    val = w_emax[t, 2, 2, 0, 1, 1, 0, 0, 0, 1]
    age = 17 + t
    marker = " *" if age < 22 else ""
    print(f"    t={t:2d} (age {age:2d}): {val:12.2f}{marker}")

# Compare married vs single emax to understand marriage incentives
print("\n  MARRIED vs SINGLE emax comparison (wife, HS, med ability, 0 kids):")
print(f"  {'t':>3} {'age':>4} {'married_w':>12} {'single_w':>12} {'diff':>10}")
for t in range(1, 30):
    m_val = w_emax[t, 0, 0, 0, 1, 1, 0, 0, 0, 1]
    s_val = w_s_emax[t, 0, 0, 1, 0, 0]
    diff = m_val - s_val if m_val != float('-inf') and s_val != float('-inf') else float('nan')
    print(f"  {t:3d} {17+t:4d} {m_val:12.2f} {s_val:12.2f} {diff:10.2f}")

print()
print("=" * 60)
print("4. EMAX AT INVALID CELLS (should be -inf or 0)")
print("=" * 60)
# Check that SC emax at t=1,2 (ages 18,19) is empty
for t in [1, 2]:
    val = w_emax[t, 1, 0, 0, 1, 1, 0, 0, 0, 1]
    print(f"  w_emax[t={t}, SC, HS, ...] = {val}")
    val = w_s_emax[t, 1, 0, 1, 0, 0]
    print(f"  w_s_emax[t={t}, SC, ...] = {val}")
# CG at t=1-4
for t in [1, 2, 3, 4]:
    val = w_emax[t, 2, 0, 0, 1, 1, 0, 0, 0, 1]
    print(f"  w_emax[t={t}, CG, HS, ...] = {val}")
    val = w_s_emax[t, 2, 0, 1, 0, 0]
    print(f"  w_s_emax[t={t}, CG, ...] = {val}")
