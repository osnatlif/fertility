"""Test that husband/wife education draws match expected distributions."""
import numpy as np
import cohorts
cohorts.cohort = "1960white"

from seed import seed
import draw_husband
import draw_wife

seed(1)
np.random.seed(1)

# Test husband draw distribution at various ages
print("HUSBAND EDUCATION DRAW TEST (10000 draws per age)")
print(f"{'age':>4} {'HS%':>8} {'SC%':>8} {'CG%':>8}  expected: {'HS%':>8} {'SC%':>8} {'CG%':>8}")

edu_dist_m = np.loadtxt("input/education_dist_m1960white.txt")

wife = draw_wife.Wife()
for age in [18, 19, 20, 22, 25, 30, 35, 40, 45]:
    counts = [0, 0, 0]
    wife.set_age(age)
    for _ in range(10000):
        h = draw_husband.draw_husband(wife)
        counts[h.schooling] += 1
    total = sum(counts)
    row = edu_dist_m[age - 18]
    print(f"{age:4d} {counts[0]/total:8.3f} {counts[1]/total:8.3f} {counts[2]/total:8.3f}"
          f"  expected: {row[1]:8.3f} {row[2]:8.3f} {row[3]:8.3f}")

# Test wife draw distribution
print("\nWIFE EDUCATION DRAW TEST (10000 draws per age)")
print(f"{'age':>4} {'HS%':>8} {'SC%':>8} {'CG%':>8}  expected: {'HS%':>8} {'SC%':>8} {'CG%':>8}")

edu_dist_f = np.loadtxt("input/education_dist_f1960white.txt")

husband = draw_husband.Husband()
for age in [18, 19, 20, 22, 25, 30, 35, 40, 45]:
    counts = [0, 0, 0]
    husband.set_age(age)
    for _ in range(10000):
        w = draw_wife.draw_wife(husband)
        counts[w.schooling] += 1
    total = sum(counts)
    row = edu_dist_f[age - 18]
    print(f"{age:4d} {counts[0]/total:8.3f} {counts[1]/total:8.3f} {counts[2]/total:8.3f}"
          f"  expected: {row[1]:8.3f} {row[2]:8.3f} {row[3]:8.3f}")
