"""
Diagnostic for w_emax / h_emax monotonicity violations in husband_school.

Hypothesis: violations are explained by bilateral marriage failure in some
cells -- when marriage never fires in any of the DRAW_B backward draws,
w_emax collapses to wife_single_outside (independent of husband_school),
making off-diagonal husband-school cells exactly equal to each other.

Output: per-EMAX classification of violation cells:
  A = monotone in husband_school (no violation)
  B = "exact-equal off-diagonals" (consistent with marriage-never-fires)
  C = inversion but off-diagonals NOT equal (=> residual bug to explain)
"""
import numpy as np
import sys
import cohorts

cohort_name = sys.argv[1] if len(sys.argv) > 1 else "1960white"
cohorts.cohort = cohort_name
import constant_parameters as c

EMAX_DIR = "emax_" + cohort_name + "/"
MIN_T = [1, 3, 5]  # entry period for HS/SC/CG (AGE_VALUES - 17)

# tolerance for "equal" -- absolute, since EMAX values are O(10^3..10^4)
EQ_TOL = 1e-6

def classify(triple, wife_school):
    """Given EMAX values for husband_school = [0, 1, 2], classify the cell.
    Returns one of: 'mono', 'exact_eq_off', 'inversion_unequal'.
    """
    # check monotonicity
    if triple[0] <= triple[1] <= triple[2]:
        return "mono"
    # not monotone -> categorize
    off_diag_idx = [s for s in (0, 1, 2) if s != wife_school]
    off_diag_vals = [triple[s] for s in off_diag_idx]
    if abs(off_diag_vals[0] - off_diag_vals[1]) < EQ_TOL:
        return "exact_eq_off"
    return "inversion_unequal"


def diagnose(filename):
    data = np.load(filename)
    print(f"\n===== {filename}  shape={data.shape} =====")
    mono = 0
    exact_eq = 0
    inversion = 0
    examples = []
    # axes: t, school_w, school_h, kids, ability_w, ability_h, kb5, we, he, mq
    for t in range(1, c.max_period_f):
        for school_w in range(c.school_size_f):
            if t < MIN_T[school_w]:
                continue
            # require all 3 husband schools valid
            if t < max(MIN_T):
                continue
            for k in range(c.kids_size_f):
                for aw in range(c.ability_size_f):
                    for ah in range(c.ability_size_f):
                        for kb5 in range(c.kids_below_5_size_f):
                            if kb5 > k:
                                continue
                            for we in range(c.emp_size_f):
                                for he in range(c.emp_size_f):
                                    for mq in range(c.match_quality_size_f):
                                        triple = [data[t, school_w, sh, k, aw, ah, kb5, we, he, mq] for sh in range(3)]
                                        kind = classify(triple, school_w)
                                        if kind == "mono":
                                            mono += 1
                                        elif kind == "exact_eq_off":
                                            exact_eq += 1
                                        else:
                                            inversion += 1
                                            if len(examples) < 10:
                                                examples.append((triple, [t, school_w, ":", k, aw, ah, kb5, we, he, mq]))
    total = mono + exact_eq + inversion
    print(f"  total cells checked:       {total}")
    print(f"  monotone:                  {mono}  ({100*mono/total:.1f}%)")
    print(f"  exact-eq off-diag (hyp.):  {exact_eq}  ({100*exact_eq/total:.1f}%)")
    print(f"  inversion, off-diag !=:    {inversion}  ({100*inversion/total:.1f}%)")
    if examples:
        print(f"\n  first {len(examples)} 'inversion_unequal' examples:")
        for vals, idx in examples:
            print(f"    {np.array(vals).round(3)}  @ {idx}")


diagnose(EMAX_DIR + "w_emax.npy")
diagnose(EMAX_DIR + "h_emax.npy")
