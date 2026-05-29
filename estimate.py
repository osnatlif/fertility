"""Structural estimation (indirect inference) for the 1960white cohort.

Nelder-Mead over a 16-parameter set. Objective = total moment MSE returned by
forward_simulation. Each evaluation: write theta into the parameter object `p`,
re-solve the backward EMAX, run the forward simulation (silent), return the total.

The objective is DETERMINISTIC in theta (calculate_emax and forward_simulation
both reseed), so the optimizer sees a smooth surface (common random numbers).

Optimization is done in SCALED units (theta / SCALE) so Nelder-Mead's simplex is
roughly isotropic across the very different parameter magnitudes.

Every evaluation is appended to estimate_log.csv. The run is resumable: on start
it reads the best row so far and warm-starts from it.

Usage:
    python estimate.py            # coarse pass (default maxfev)
    python estimate.py 600        # custom max function evaluations
"""
import cohorts
cohorts.cohort = "1960white"   # MUST be set before importing the model modules

import sys
import csv
import os
import time
import numpy as np
from scipy.optimize import minimize

from parameters import p
from calculate_emax import (create_married_emax, create_single_w_emax,
                            create_single_h_emax, calculate_emax)
import forward_simulation as fs

# ---------------------------------------------------------------------------
# Estimated parameter spec per PHASE: (name on `p`, lower, upper, scale step).
# Anything NOT listed in the active phase is FIXED at its current `p` value.
#   marriage   : marriage/fertility block (the original 16-param set)
#   employment : 4 leisure + wife's 12 offer/layoff hazards (men's hazards FIXED)
# The 3 lambda15 (exp^2) terms are capped at 0 so the life-cycle hazard can only
# bend concave (offers flatten with experience), never accelerate.
# ---------------------------------------------------------------------------
PHASES = {
    "marriage": [
        # name          lo      hi     scale
        ("dc_w",      -800.0,  -20.0,  60.0),
        ("dc_h",      -800.0,  -20.0,  60.0),
        ("taste_hs",    50.0,  600.0,  40.0),
        ("taste_sc",    50.0,  600.0,  40.0),
        ("taste_cg",    50.0,  600.0,  60.0),
        ("mconst1_h",    0.0,  200.0,  25.0),
        ("mconst1_w",    0.0,  200.0,  25.0),
        ("mconst2_h",    0.0,  200.0,  20.0),
        ("mconst2_w",    0.0,  200.0,  20.0),
        ("alpha3_w_m",   0.0,  120.0,  12.0),
        ("alpha3_w_s",   0.0,   30.0,   5.0),
        ("alpha3_h_m",   0.0,  120.0,  15.0),
        ("alpha2w0",     0.2,    2.0,   0.2),
        ("alpha2w1",    -0.5,    0.5,   0.1),
        ("sigma_q",      0.25,   2.0,   0.12),
        ("omega3",      -3.0,    0.0,   0.30),
    ],
    "employment": [
        # name             lo      hi      scale
        # --- leisure / disutility of work ---
        ("alpha2w0",       0.2,    2.0,    0.2),
        ("alpha2w1",      -0.5,    0.5,    0.1),
        ("alpha2h0",       0.2,    2.0,    0.2),
        ("alpha2h1",      -0.5,    0.5,    0.1),
        # --- wife full-time offer hazard ---
        ("lambda0_w_ft",  -4.0,    1.0,    0.5),
        ("lambda1_w_ft",  -0.05,   0.15,   0.02),
        ("lambda15_w_ft", -0.005,  0.0,    0.001),
        ("lambda2_w_ft",   0.0,    1.5,    0.2),
        # --- wife part-time offer hazard ---
        ("lambda0_w_pt",  -4.5,    0.0,    0.5),
        ("lambda1_w_pt",  -0.05,   0.15,   0.02),
        ("lambda15_w_pt", -0.005,  0.0,    0.001),
        ("lambda2_w_pt",   0.0,    1.5,    0.2),
        # --- wife not-laid-off hazard ---
        ("lambda0_w_f",   -1.0,    4.0,    0.5),
        ("lambda1_w_f",   -0.05,   0.15,   0.02),
        ("lambda15_w_f",  -0.005,  0.0,    0.001),
        ("lambda2_w_f",    0.0,    1.5,    0.2),
    ],
}

PHASE_FILES = {
    "marriage":   ("estimate_log.csv",            "estimate_best.txt"),
    "employment": ("estimate_log_employment.csv", "estimate_best_employment.txt"),
}
# marriage-phase converged best, applied as fixed background in the employment phase
MARRIAGE_BEST_FILE = "estimate_best.txt"

# module-level globals; set by select_phase()
SPEC = NAMES = LO = HI = SCALE = LOG_FILE = BEST_FILE = None
NP_ = 0


def select_phase(phase):
    """Point the module globals at the requested phase's spec and log files."""
    global SPEC, NAMES, LO, HI, SCALE, NP_, LOG_FILE, BEST_FILE
    if phase not in PHASES:
        raise SystemExit(f"unknown phase '{phase}'; choose from {list(PHASES)}")
    SPEC   = PHASES[phase]
    NAMES  = [s[0] for s in SPEC]
    LO     = np.array([s[1] for s in SPEC])
    HI     = np.array([s[2] for s in SPEC])
    SCALE  = np.array([s[3] for s in SPEC])
    NP_    = len(SPEC)
    LOG_FILE, BEST_FILE = PHASE_FILES[phase]


select_phase("marriage")   # default so plain imports still resolve the globals


def current_theta():
    """Read the current values of the estimated params off `p`."""
    return np.array([float(getattr(p, n)) for n in NAMES])


def set_params(theta):
    for name, val in zip(NAMES, theta):
        setattr(p, name, float(val))


def run_model(display=False):
    """One full solve+simulate at the current `p`; returns scalar total objective."""
    w_emax   = create_married_emax()
    h_emax   = create_married_emax()
    w_s_emax = create_single_w_emax()
    h_s_emax = create_single_h_emax()
    calculate_emax(w_emax, h_emax, w_s_emax, h_s_emax, False)
    return float(fs.forward_simulation(w_emax, h_emax, w_s_emax, h_s_emax, False, display))


# ---- evaluation bookkeeping ----
_state = {"n": 0, "best": np.inf, "best_theta": None, "t0": time.time()}


def objective_scaled(u):
    """u is theta/SCALE. Unscale, clip to bounds, evaluate, log."""
    theta = np.clip(u * SCALE, LO, HI)
    set_params(theta)
    total = run_model(display=False)
    _state["n"] += 1
    if total < _state["best"]:
        _state["best"] = total
        _state["best_theta"] = theta.copy()
        _save_best(theta, total)
    with open(LOG_FILE, "a", newline="") as f:
        csv.writer(f).writerow([_state["n"], f"{total:.4f}"] + [f"{x:.6f}" for x in theta])
    flag = "  *BEST*" if total == _state["best"] else ""
    el = (time.time() - _state["t0"]) / 60.0
    print(f"eval {_state['n']:4d} | obj {total:9.2f} | best {_state['best']:9.2f} | {el:6.1f} min{flag}",
          flush=True)
    return total


def _save_best(theta, total):
    with open(BEST_FILE, "w") as f:
        f.write(f"# best objective: {total:.4f}  ({_state['n']} evals)\n")
        for name, val in zip(NAMES, theta):
            f.write(f"p.{name} = {val:.6f}\n")


def best_from_log():
    """Return (obj, theta) of the best evaluation recorded in the log, else (inf, None).
    The log is the source of truth (written from the actual evaluated theta each call)."""
    best_obj, best_theta = np.inf, None
    if not os.path.exists(LOG_FILE):
        return best_obj, best_theta
    with open(LOG_FILE) as f:
        for row in csv.reader(f):
            if not row or row[0] == "eval":
                continue
            try:
                obj = float(row[1]); th = np.array([float(x) for x in row[2:2+NP_]])
            except (ValueError, IndexError):
                continue
            if obj < best_obj and th.size == NP_:
                best_obj, best_theta = obj, th
    return best_obj, best_theta


def apply_best_file(path):
    """Load a `p.name = value` best-file onto `p` to pin params as fixed background.
    Used by the employment phase to hold the marriage/fertility params at their
    converged values while only the employment block is moved."""
    if not os.path.exists(path):
        print(f"  WARNING: {path} not found; using parameters.py values as background")
        return
    n = 0
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("p."):
                continue
            try:
                lhs, rhs = line.split("=", 1)
                name = lhs.strip()[2:]                      # drop leading "p."
                setattr(p, name, float(rhs.split("#")[0].strip()))
                n += 1
            except (ValueError, IndexError):
                continue
    print(f"  applied {n} params from {path} as fixed background")


def load_warm_start():
    """If a log exists, warm-start from the best row recorded so far."""
    best_obj, best_theta = best_from_log()
    if best_theta is not None:
        print(f"warm-starting from logged best: obj={best_obj:.2f}")
        return best_theta
    return current_theta()


def main():
    # args (any order): a phase name from PHASES, and/or an int maxfev
    phase, maxfev = "marriage", 300
    for a in sys.argv[1:]:
        if a in PHASES:
            phase = a
        else:
            try:
                maxfev = int(a)
            except ValueError:
                pass
    select_phase(phase)
    print(f"=== PHASE: {phase}  |  {NP_} params: {', '.join(NAMES)} ===", flush=True)

    # employment phase: hold the marriage/fertility params at their converged best
    if phase == "employment":
        print("pinning marriage/fertility params at converged best:")
        apply_best_file(MARRIAGE_BEST_FILE)

    if not os.path.exists(LOG_FILE):
        with open(LOG_FILE, "w", newline="") as f:
            csv.writer(f).writerow(["eval", "objective"] + NAMES)

    theta0 = load_warm_start()
    print("starting objective check...", flush=True)
    set_params(theta0)
    obj0 = run_model(display=False)
    print(f"start obj = {obj0:.2f}  at theta0 = "
          + ", ".join(f"{n}={v:.3f}" for n, v in zip(NAMES, theta0)), flush=True)

    u0 = theta0 / SCALE
    bounds_scaled = [(lo / s, hi / s) for lo, hi, s in zip(LO, HI, SCALE)]

    res = minimize(
        objective_scaled, u0, method="Nelder-Mead", bounds=bounds_scaled,
        options={"maxfev": maxfev, "fatol": 1.0, "xatol": 0.01, "disp": True},
    )

    best_obj, best_theta = best_from_log()      # log is source of truth
    if best_theta is None:                       # fallback if log unreadable
        best_obj, best_theta = _state["best"], _state["best_theta"]
    print("\n==================== ESTIMATION DONE ====================")
    print(f"evals: {_state['n']}   best objective: {best_obj:.4f}")
    print(f"best params written to {BEST_FILE}")
    # final re-solve WITH moment tables printed
    set_params(best_theta)
    print("\n--- final moments at best parameters ---")
    run_model(display=True)


if __name__ == "__main__":
    main()
