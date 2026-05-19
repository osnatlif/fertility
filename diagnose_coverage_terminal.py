"""
Tier-2 diagnostics #5 (-inf coverage) and #6 (terminal-period properties).
Read-only; uses the dumped .npy files. No model code changes.
"""
import numpy as np
import sys
import cohorts

cohort_name = sys.argv[1] if len(sys.argv) > 1 else "1960white"
cohorts.cohort = cohort_name
import constant_parameters as c

EMAX_DIR = "emax_" + cohort_name + "/"
MIN_T = [1, 3, 5]
T_TERMINAL = c.max_period_f - 1


def count_inf_reachable(name, data, reachability_fn):
    """For every index tuple, ask reachability_fn(*idx) -> bool.
    Count -inf cells among reachable indices."""
    inf_count = 0
    reachable_count = 0
    first_inf = []
    it = np.ndindex(*data.shape)
    for idx in it:
        if not reachability_fn(*idx):
            continue
        reachable_count += 1
        v = data[idx]
        if v == float("-inf") or np.isnan(v):
            inf_count += 1
            if len(first_inf) < 5:
                first_inf.append(idx)
    print(f"\n[{name}] reachable cells: {reachable_count}    -inf or nan in reachable: {inf_count}")
    if first_inf:
        print("  first 5:", first_inf)


# ------------------------- coverage (#5) -------------------------

# w_emax / h_emax: axes t, sw, sh, k, aw, ah, kb5, we, he, mq
def reachable_married(t, sw, sh, k, aw, ah, kb5, we, he, mq):
    if t < 1:                  # t=0 is never written
        return False
    if t < MIN_T[sw]:
        return False
    if t < MIN_T[sh]:
        return False
    if kb5 > k:                # kb5 capped at kids
        return False
    return True

# w_s_emax: axes t, sw, k, aw, kb5, we
def reachable_single_w(t, sw, k, aw, kb5, we):
    if t < 1:
        return False
    if t < MIN_T[sw]:
        return False
    if kb5 > k:
        return False
    return True

# h_s_emax: axes t, sh, ah, he
def reachable_single_h(t, sh, ah, he):
    if t < 1:
        return False
    if t < MIN_T[sh]:
        return False
    return True


print("===================== #5: -inf in reachable cells =====================")
count_inf_reachable("w_emax",   np.load(EMAX_DIR + "w_emax.npy"),   reachable_married)
count_inf_reachable("h_emax",   np.load(EMAX_DIR + "h_emax.npy"),   reachable_married)
count_inf_reachable("w_s_emax", np.load(EMAX_DIR + "w_s_emax.npy"), reachable_single_w)
count_inf_reachable("h_s_emax", np.load(EMAX_DIR + "h_s_emax.npy"), reachable_single_h)


# ------------------------- terminal-period properties (#6) -------------------------

print("\n===================== #6: terminal-period properties =====================")
print(f"  t_terminal = max_period - 1 = {T_TERMINAL}")

# Finite check at terminal
def finite_check(name, data, reach_fn, t):
    # extract slice at t and walk all indices
    bad = 0
    total = 0
    sub = data[t]
    for idx in np.ndindex(*sub.shape):
        full = (t,) + idx
        if not reach_fn(*full):
            continue
        total += 1
        v = sub[idx]
        if not np.isfinite(v):
            bad += 1
    print(f"  [{name}] reachable cells at t={t}: {total}    non-finite: {bad}")

finite_check("w_emax",   np.load(EMAX_DIR + "w_emax.npy"),   reachable_married, T_TERMINAL)
finite_check("h_emax",   np.load(EMAX_DIR + "h_emax.npy"),   reachable_married, T_TERMINAL)
finite_check("w_s_emax", np.load(EMAX_DIR + "w_s_emax.npy"), reachable_single_w, T_TERMINAL)
finite_check("h_s_emax", np.load(EMAX_DIR + "h_s_emax.npy"), reachable_single_h, T_TERMINAL)


def monotone_violations(name, swept_axis_name, slicer, valid_iter):
    """Sweep `valid_iter`, build a triple via `slicer(*idx)` of length 3,
    classify and count violations."""
    mono = 0; viols = 0
    examples = []
    for idx in valid_iter:
        triple = slicer(idx)
        triple = np.asarray(triple)
        if np.any(~np.isfinite(triple)):
            continue
        if triple[0] <= triple[1] <= triple[2]:
            mono += 1
        else:
            viols += 1
            if len(examples) < 5:
                examples.append((triple.round(3), idx))
    total = mono + viols
    if total == 0:
        print(f"  [{name}] {swept_axis_name}: 0 cells")
        return
    print(f"  [{name}] sweep over {swept_axis_name} at t={T_TERMINAL}:  mono={mono}/{total}  violations={viols}  ({100*viols/total:.1f}%)")
    for arr, idx in examples:
        print(f"     {arr}   idx={idx}")


print("\n  -- h_s_emax (no kids; no bilateral with own state) --")
h_s = np.load(EMAX_DIR + "h_s_emax.npy")
# h_s shape: [t, school, ability, he]; sweep school for each (ability, he)
def gen_h_s_school():
    for ah in range(c.ability_size_f):
        for he in range(c.emp_size_f):
            yield (ah, he)
def slice_h_s_school(ah_he):
    ah, he = ah_he
    valid_schools = [sh for sh in range(c.school_size_f) if T_TERMINAL >= MIN_T[sh]]
    if len(valid_schools) != 3:
        return [0, 0, 0]   # skip; classification will see mono
    return [h_s[T_TERMINAL, sh, ah, he] for sh in valid_schools]
monotone_violations("h_s_emax", "own_school", slice_h_s_school, gen_h_s_school())

def gen_h_s_ability():
    for sh in range(c.school_size_f):
        if T_TERMINAL < MIN_T[sh]:
            continue
        for he in range(c.emp_size_f):
            yield (sh, he)
def slice_h_s_ability(sh_he):
    sh, he = sh_he
    return [h_s[T_TERMINAL, sh, ah, he] for ah in range(c.ability_size_f)]
monotone_violations("h_s_emax", "own_ability", slice_h_s_ability, gen_h_s_ability())


print("\n  -- w_s_emax (kids dim present; bilateral marriage active) --")
w_s = np.load(EMAX_DIR + "w_s_emax.npy")
# w_s shape: [t, school, kids, ability, kb5, we]
def gen_w_s_school():
    for k in range(c.kids_size_f):
        for aw in range(c.ability_size_f):
            for kb5 in range(c.kids_below_5_size_f):
                if kb5 > k:
                    continue
                for we in range(c.emp_size_f):
                    yield (k, aw, kb5, we)
def slice_w_s_school(idx):
    k, aw, kb5, we = idx
    valid_schools = [s for s in range(c.school_size_f) if T_TERMINAL >= MIN_T[s]]
    if len(valid_schools) != 3:
        return [0, 0, 0]
    return [w_s[T_TERMINAL, s, k, aw, kb5, we] for s in valid_schools]
monotone_violations("w_s_emax", "own_school", slice_w_s_school, gen_w_s_school())

def gen_w_s_ability():
    for s in range(c.school_size_f):
        if T_TERMINAL < MIN_T[s]:
            continue
        for k in range(c.kids_size_f):
            for kb5 in range(c.kids_below_5_size_f):
                if kb5 > k:
                    continue
                for we in range(c.emp_size_f):
                    yield (s, k, kb5, we)
def slice_w_s_ability(idx):
    s, k, kb5, we = idx
    return [w_s[T_TERMINAL, s, k, aw, kb5, we] for aw in range(c.ability_size_f)]
monotone_violations("w_s_emax", "own_ability", slice_w_s_ability, gen_w_s_ability())
