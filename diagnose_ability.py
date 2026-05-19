"""
Classify ability monotonicity violations in w_emax / h_emax / w_s_emax.

For each ability dimension, fix all other state, sweep ability in {0,1,2},
and classify:
  - mono           : non-decreasing -> expected
  - tiny_inversion : non-monotone but max absolute drop < 1.0 (numerical noise)
  - small_inversion: drop in [1, 50]
  - big_inversion  : drop > 50 (structural)

Also show first 10 examples of each non-mono category for inspection.
"""
import numpy as np
import sys
import cohorts

cohort_name = sys.argv[1] if len(sys.argv) > 1 else "1960white"
cohorts.cohort = cohort_name
import constant_parameters as c

EMAX_DIR = "emax_" + cohort_name + "/"
MIN_T = [1, 3, 5]

def max_drop(arr):
    """Largest backward step. arr must have no -inf entries."""
    drops = []
    prev = arr[0]
    for v in arr[1:]:
        if v < prev:
            drops.append(prev - v)
        prev = v
    return max(drops) if drops else 0.0

def classify(arr):
    arr = np.asarray(arr)
    if np.all(arr[:-1] <= arr[1:] + 1e-9):
        return "mono", 0.0
    d = max_drop(arr)
    if d < 1.0:
        return "tiny", d
    if d < 50.0:
        return "small", d
    return "big", d


def sweep(name, data, swap_axis, fixed_axes, validity_fn):
    """
    Sweep `data` along `swap_axis` (length 3), fixing all other axes.
    fixed_axes: list of (axis_name, range) for the loop nest.
    validity_fn(idx_dict) -> bool: filter cells.
    """
    counts = {"mono": 0, "tiny": 0, "small": 0, "big": 0}
    examples = {"tiny": [], "small": [], "big": []}

    def loop(level, idx):
        if level == len(fixed_axes):
            if not validity_fn(idx):
                return
            # build full slice with swap_axis varying
            sel = [slice(None)] * data.ndim
            for ax_name, ax_idx in idx.items():
                ax_pos = axis_pos[ax_name]
                sel[ax_pos] = ax_idx
            arr = data[tuple(sel)]   # 1-D length 3
            kind, drop = classify(arr)
            counts[kind] += 1
            if kind != "mono" and len(examples[kind]) < 10:
                examples[kind].append((np.array(arr).round(3), dict(idx), drop))
            return
        ax_name, ax_range = fixed_axes[level]
        for v in ax_range:
            idx[ax_name] = v
            loop(level + 1, idx)
        del idx[ax_name]

    axis_pos = {n: i for i, n in enumerate(AX_NAMES_BY_FILE[name])}
    loop(0, {})
    total = sum(counts.values())
    print(f"\n===== {name} ({swept}) total={total} =====")
    for k in ("mono", "tiny", "small", "big"):
        if total:
            print(f"  {k:>5}: {counts[k]:>7}  ({100*counts[k]/total:5.1f}%)")
    for k in ("tiny", "small", "big"):
        if examples[k]:
            print(f"  -- first {len(examples[k])} {k} examples --")
            for arr, idx, drop in examples[k]:
                print(f"    {arr}   drop={drop:.3f}   @ {idx}")


# Axes for each EMAX file
AX_NAMES_BY_FILE = {
    "w_emax":   ["t", "school_w", "school_h", "kids", "ability_w", "ability_h", "kb5", "we", "he", "mq"],
    "h_emax":   ["t", "school_w", "school_h", "kids", "ability_w", "ability_h", "kb5", "we", "he", "mq"],
    "w_s_emax": ["t", "school_w", "kids", "ability_w", "kb5", "we"],
}


# ===================== w_emax / h_emax: ability_w =====================
for name in ("w_emax", "h_emax"):
    data = np.load(EMAX_DIR + name + ".npy")
    swept = "ability_w"
    print(f"\n##### {name} sweep over {swept} #####")
    counts = {"mono": 0, "tiny": 0, "small": 0, "big": 0}
    examples = {"tiny": [], "small": [], "big": []}
    for t in range(1, c.max_period_f):
        for sw in range(c.school_size_f):
            if t < MIN_T[sw]:
                continue
            for sh in range(c.school_size_f):
                if t < MIN_T[sh]:
                    continue
                for k in range(c.kids_size_f):
                    for ah in range(c.ability_size_f):
                        for kb5 in range(c.kids_below_5_size_f):
                            if kb5 > k:
                                continue
                            for we in range(c.emp_size_f):
                                for he in range(c.emp_size_f):
                                    for mq in range(c.match_quality_size_f):
                                        arr = data[t, sw, sh, k, :, ah, kb5, we, he, mq]
                                        kind, drop = classify(arr)
                                        counts[kind] += 1
                                        if kind != "mono" and len(examples[kind]) < 5:
                                            examples[kind].append((np.array(arr).round(3),
                                                                   [t, sw, sh, k, ":", ah, kb5, we, he, mq], drop))
    total = sum(counts.values())
    print(f"  total = {total}")
    for k in ("mono", "tiny", "small", "big"):
        print(f"  {k:>5}: {counts[k]:>7}  ({100*counts[k]/total:5.1f}%)")
    for k in ("tiny", "small", "big"):
        if examples[k]:
            print(f"  -- first {len(examples[k])} {k} examples --")
            for arr, idx, drop in examples[k]:
                print(f"    {arr}   drop={drop:.3f}   @ {idx}")

# ===================== w_emax / h_emax: ability_h =====================
for name in ("w_emax", "h_emax"):
    data = np.load(EMAX_DIR + name + ".npy")
    swept = "ability_h"
    print(f"\n##### {name} sweep over {swept} #####")
    counts = {"mono": 0, "tiny": 0, "small": 0, "big": 0}
    examples = {"tiny": [], "small": [], "big": []}
    for t in range(1, c.max_period_f):
        for sw in range(c.school_size_f):
            if t < MIN_T[sw]:
                continue
            for sh in range(c.school_size_f):
                if t < MIN_T[sh]:
                    continue
                for k in range(c.kids_size_f):
                    for aw in range(c.ability_size_f):
                        for kb5 in range(c.kids_below_5_size_f):
                            if kb5 > k:
                                continue
                            for we in range(c.emp_size_f):
                                for he in range(c.emp_size_f):
                                    for mq in range(c.match_quality_size_f):
                                        arr = data[t, sw, sh, k, aw, :, kb5, we, he, mq]
                                        kind, drop = classify(arr)
                                        counts[kind] += 1
                                        if kind != "mono" and len(examples[kind]) < 5:
                                            examples[kind].append((np.array(arr).round(3),
                                                                   [t, sw, sh, k, aw, ":", kb5, we, he, mq], drop))
    total = sum(counts.values())
    print(f"  total = {total}")
    for k in ("mono", "tiny", "small", "big"):
        print(f"  {k:>5}: {counts[k]:>7}  ({100*counts[k]/total:5.1f}%)")
    for k in ("tiny", "small", "big"):
        if examples[k]:
            print(f"  -- first {len(examples[k])} {k} examples --")
            for arr, idx, drop in examples[k]:
                print(f"    {arr}   drop={drop:.3f}   @ {idx}")

# ===================== w_s_emax: ability_w =====================
data = np.load(EMAX_DIR + "w_s_emax.npy")
swept = "ability_w"
print(f"\n##### w_s_emax sweep over {swept} #####")
counts = {"mono": 0, "tiny": 0, "small": 0, "big": 0}
examples = {"tiny": [], "small": [], "big": []}
for t in range(1, c.max_period_f):
    for sw in range(c.school_size_f):
        if t < MIN_T[sw]:
            continue
        for k in range(c.kids_size_f):
            for kb5 in range(c.kids_below_5_size_f):
                if kb5 > k:
                    continue
                for we in range(c.emp_size_f):
                    arr = data[t, sw, k, :, kb5, we]
                    kind, drop = classify(arr)
                    counts[kind] += 1
                    if kind != "mono" and len(examples[kind]) < 5:
                        examples[kind].append((np.array(arr).round(3),
                                               [t, sw, k, ":", kb5, we], drop))
total = sum(counts.values())
print(f"  total = {total}")
for k in ("mono", "tiny", "small", "big"):
    print(f"  {k:>5}: {counts[k]:>7}  ({100*counts[k]/total:5.1f}%)")
for k in ("tiny", "small", "big"):
    if examples[k]:
        print(f"  -- first {len(examples[k])} {k} examples --")
        for arr, idx, drop in examples[k]:
            print(f"    {arr}   drop={drop:.3f}   @ {idx}")
