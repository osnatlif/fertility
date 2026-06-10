"""Parallel CMA-ES estimation -- same phase mechanism as estimate.py, but uses
the cma package for the optimizer and a multiprocessing pool of workers so each
generation's population is evaluated in parallel. Designed for the 16-CPU AWS
box (one worker per core); also fine to run locally with fewer workers.

Architecture:
  * Reuses PHASES, PHASE_FILES, apply_latest_state, run_model, set_params,
    current_theta, best_from_log from estimate.py -- no duplicated logic.
  * Each worker is a fresh Python process (multiprocessing 'spawn' on Windows).
    On startup it select_phase(phase) and apply_latest_state() so every worker
    boots into the same converged background.
  * CMA-ES sigma0=1 with per-param step via CMA_stds (matches sequential SCALE).
  * Native bounds, tolfun=1.0, tolx=0.01 (matches the sequential NM tolerances).
  * Common random numbers: each run_model call reseeds via seed(1) inside
    calculate_emax / forward_simulation, so the objective is deterministic in
    theta regardless of which worker evaluates it.

Usage:
    python estimate_parallel.py                       # phase=marriage maxgen=100
    python estimate_parallel.py employment 80         # employment phase, 80 gen
    python estimate_parallel.py all 50                # full union phase
    python estimate_parallel.py 60 wage               # args any order
"""
import cohorts
cohorts.cohort = "1960white"

import sys
import os
import csv
import time
import numpy as np
from multiprocessing import get_context

try:
    import cma
except ImportError:
    raise SystemExit(
        "The `cma` package is required for parallel estimation.\n"
        "Install it with:   python -m pip install cma"
    )

# Reuse all of estimate.py's setup -- phase spec, files, model wrappers
import estimate as e


# -----------------------------------------------------------------------------
# Defaults (tweak here if the 16-CPU box has a different layout)
# -----------------------------------------------------------------------------
POPSIZE   = 16        # CMA-ES population per generation
N_WORKERS = 16        # multiprocessing pool size  (one eval per worker per gen)
SIGMA0    = 1.0       # initial CMA sigma (per-param step encoded via CMA_stds)
TOLFUN    = 1.0       # stop when generation best improves by < TOLFUN
TOLX      = 0.01      # stop when step in scaled coords < TOLX
SEED      = 1         # CMA-ES internal RNG seed (CRN already handled inside model)


# -----------------------------------------------------------------------------
# Worker process functions  (fresh Python interp per worker)
# -----------------------------------------------------------------------------
def _worker_init(phase):
    """Per-worker one-time setup: select the phase and pin the latest state."""
    import estimate as we
    we.select_phase(phase)
    # NOTE: apply_latest_state is verbose; if 16 workers print at once the log
    # gets noisy. Silence the per-worker pin -- the main process already printed
    # the canonical pinning summary at startup.
    import builtins as _b
    _orig_print = _b.print
    _b.print = lambda *a, **kw: None
    try:
        we.apply_latest_state()
    finally:
        _b.print = _orig_print


def _worker_eval(theta_list):
    """Evaluate one theta in this worker. theta_list is a plain list for safe
    pickling across the spawn boundary. Returns the scalar objective."""
    import estimate as we
    theta = np.asarray(theta_list, dtype=float)
    we.set_params(theta)
    return float(we.run_model(display=False))


# -----------------------------------------------------------------------------
# Logging helpers  (main process only -- no inter-worker locks)
# -----------------------------------------------------------------------------
def _log_eval(log_file, eval_no, theta, total):
    with open(log_file, "a", newline="") as f:
        csv.writer(f).writerow(
            [eval_no, f"{total:.4f}"] + [f"{x:.6f}" for x in theta]
        )


def _save_best(best_file, names, theta, total, eval_no):
    with open(best_file, "w") as f:
        f.write(f"# best objective: {total:.4f}  ({eval_no} evals)\n")
        for name, val in zip(names, theta):
            f.write(f"p.{name} = {val:.6f}\n")


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def parse_args(argv):
    """Parse [phase] [maxgen] in any order. Returns (phase, maxgen)."""
    phase, maxgen = "marriage", 100
    for a in argv:
        if a in e.PHASES:
            phase = a
        else:
            try:
                maxgen = int(a)
            except ValueError:
                pass
    return phase, maxgen


def main():
    phase, maxgen = parse_args(sys.argv[1:])
    e.select_phase(phase)
    log_file, best_file = e.PHASE_FILES[phase]
    names, lo, hi, scale = e.NAMES, e.LO, e.HI, e.SCALE
    npars = e.NP_

    print(f"=== PARALLEL CMA-ES  |  phase={phase}  |  {npars} params  "
          f"|  popsize={POPSIZE}  |  workers={N_WORKERS}  |  maxgen={maxgen} ===",
          flush=True)

    # Apply latest converged state in the MAIN process so theta0 reads off the
    # right p attrs.  Workers will apply the same state independently in their
    # init hook (and silently).
    print("\npinning state from latest phase best-files:")
    e.apply_latest_state()

    # Create the log header if this is a fresh run for this phase
    if not os.path.exists(log_file):
        with open(log_file, "w", newline="") as f:
            csv.writer(f).writerow(["eval", "objective"] + names)

    # Warm-start: best logged theta for THIS phase, else current p values
    best_obj_logged, best_theta_logged = e.best_from_log()
    if best_theta_logged is not None:
        theta0 = best_theta_logged
        print(f"\nwarm-starting from logged best for '{phase}': "
              f"obj={best_obj_logged:.2f}")
    else:
        theta0 = e.current_theta()
        print(f"\nno {phase} log found; warm-starting from current p values")

    # CMA-ES options. Sigma0=1 because per-param step lives in CMA_stds.
    opts = {
        "bounds":   [lo.tolist(), hi.tolist()],
        "popsize":  POPSIZE,
        "maxiter":  maxgen,
        "verbose": -9,                       # suppress CMA's own chatter
        "CMA_stds": scale.tolist(),          # per-param step (= our SCALE)
        "tolfun":   TOLFUN,
        "tolx":     TOLX,
        "seed":     SEED,
    }
    es = cma.CMAEvolutionStrategy(theta0.tolist(), SIGMA0, opts)

    # State for the run-level loop
    eval_count = 0
    global_best_obj = best_obj_logged if best_theta_logged is not None else np.inf
    global_best_theta = best_theta_logged
    t0 = time.time()

    # Always use 'spawn' (default on Windows; explicit for safety on Linux too)
    ctx = get_context("spawn")
    print(f"\nstarting pool of {N_WORKERS} workers...", flush=True)
    with ctx.Pool(processes=N_WORKERS,
                  initializer=_worker_init,
                  initargs=(phase,)) as pool:
        gen = 0
        while not es.stop():
            thetas = es.ask()
            # Lists (not arrays) for picklable args across spawn
            objs = pool.map(_worker_eval, [list(t) for t in thetas])
            es.tell(thetas, objs)
            gen += 1

            # Log every individual in this generation; track global best
            gen_best = float("inf")
            gen_best_theta = None
            for theta, total in zip(thetas, objs):
                eval_count += 1
                _log_eval(log_file, eval_count, np.asarray(theta), total)
                if total < gen_best:
                    gen_best = total
                    gen_best_theta = np.asarray(theta)
                if total < global_best_obj:
                    global_best_obj = total
                    global_best_theta = np.asarray(theta)
                    _save_best(best_file, names, global_best_theta,
                               global_best_obj, eval_count)

            elapsed = (time.time() - t0) / 60.0
            flag = "  *NEW BEST*" if gen_best == global_best_obj else ""
            print(f"gen {gen:4d} | gen_best {gen_best:9.2f} | "
                  f"global_best {global_best_obj:9.2f} | "
                  f"evals {eval_count:5d} | {elapsed:6.1f} min{flag}",
                  flush=True)

    # Stop reason from CMA
    print(f"\nCMA-ES stop: {es.stop()}", flush=True)

    # Final re-solve at the logged best with the full moment tables printed.
    print("\n==================== PARALLEL ESTIMATION DONE ====================")
    final_obj, final_theta = e.best_from_log()
    if final_theta is None:
        final_obj, final_theta = global_best_obj, global_best_theta
    print(f"evals: {eval_count}   best objective: {final_obj:.4f}")
    print(f"best params written to {best_file}")
    e.set_params(final_theta)
    print("\n--- final moments at best parameters ---")
    e.run_model(display=True)


if __name__ == "__main__":
    main()
