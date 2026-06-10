# Estimation plan — parameter inventory (fix vs. estimate)

Decision key:
- **FIX-lit** = calibrate from literature / institutions (not estimated)
- **FIX-norm** = normalization or numerical choice (not a behavioral parameter)
- **1st-stage** = estimate outside the structural loop from auxiliary regressions (wages, transitions), then hold fixed
- **ESTIMATE** = estimated inside the structural search (indirect inference)

---

## A. Economic constants → FIX

| Param | Value | Role | Decision | Note |
|-------|------:|------|----------|------|
| `beta0` (discount) | 0.983 | discount factor | **FIX-lit** | standard; not separately identified |
| `scale` | 0.707 | couple equivalence scale | **FIX-lit** | √2 OECD-style scale |
| `eta1..eta4` | 0.194/0.293/0.367/0.423 | kids' income share | **FIX-lit** | equivalence-scale based |
| `ub_w`, `ub_h` | 6000 / 8000 | unemployment income | **FIX-lit** | institutional |
| `childcare_cost` | 5000 | per kid <5 | **FIX-lit** | data (era-adjusted) |
| `cb_const`, `cb_per_child` | 3000 / 1517 | single-mom child benefit | **FIX-lit** | AFDC/program data |
| `bp` (bargaining power) | 0.5 | Pareto weight | **FIX-norm** | symmetric; could estimate later |
| `leisure`, `leisure_part`, `home_p` | 1 / 0.5 / 0 | time endowment | **FIX-norm** | normalization |
| `ability_vector`, `match_vector`, `normal_vector` | ±1.15 | type grids | **FIX-norm** | discrete-type normalization |
| `preg_prob[age]` | data | biological fecundity | **FIX-lit** | demographic |
| `MAX_FERTILITY_AGE` | 45 | — | **FIX-lit** | demographic |
| tax brackets / deductions | data | tax system | **FIX-lit** | tax code by year |
| `exp_grid` {1,4,8,12}, `N_GH`, `N_EXP` | — | discretization | **FIX-norm** | numerical choices |
| initial-kids distribution | data file | entry fertility | **FIX-lit** | from cohort data (appendix) |

---

## B. Wage process → 1st-stage (estimate from wage data, then fix)

| Param | Value | Role | Decision |
|-------|------:|------|----------|
| `beta0_w`, `beta0_h` | 0.10 / 0.15 | ability → log wage | **1st-stage / FIX-lit** (matches AFQT ~8%/SD) |
| `beta11_w..beta23_w` | Mincer exp profile (wife) | experience returns | **1st-stage** |
| `beta11_h..beta23_h` | Mincer exp profile (husband) | experience returns | **1st-stage** |
| `beta31_w..33_w`, `beta31_h..33_h` | wage constants by edu | level | **1st-stage** (may need structural offset for selection) |
| `beta41_w..43_w`, `beta41_h..43_h` | non-employment penalty | scarring | **1st-stage** or ESTIMATE |
| `sigma_w_wage`, `sigma_h_wage` | wage shock SD | residual variance | **1st-stage** |

Rationale: the wage equation is identified directly off observed wages. Standard practice: estimate via auxiliary Mincer regressions (correcting for the model's selection), hold fixed in the structural loop. Avoids spending the expensive structural search on ~30 wage coefficients.

---

## C. Job-offer / separation & meeting → 1st-stage or ESTIMATE

| Param | Role | Decision |
|-------|------|----------|
| `lambda0/1/15/2 _w_ft`, `_w_pt`, `_w_f` | wife offer/sep probs | **1st-stage** (employment transitions) or ESTIMATE |
| `lambda*_h_ft/pt/f` | husband offer/sep probs | **1st-stage** |
| `omega3, omega4_w, omega5_w` | meeting prob by age | **ESTIMATE** (marriage hazard) |

Note: `lambda2_w_ft` we hand-tuned (0.041→0.30) — flag for ESTIMATE since it strongly affects FT employment.

---

## D. Preference parameters → ESTIMATE (the core structural set)

| Param | Value | Role | Decision | Identified by |
|-------|------:|------|----------|---------------|
| `alpha0` (CRRA) | 0.541 | consumption curvature | **FIX-lit** | RRA pinned ~0.5–2; weak ID |
| `alpha2w0`, `alpha2w1` | 0.8 / 0.15 | wife leisure, ×kids | **ESTIMATE** | female employment |
| `alpha2h0`, `alpha2h1` | 0.5 / 0.1 | husband leisure, ×kids | **ESTIMATE** | male employment |
| `alpha3_w_m`, `alpha3_w_s` | 27 / 3 | wife kid utility (m/s) | **ESTIMATE** | fertility married/unmarried |
| `alpha3_h_m`, `alpha3_h_s` | 55 / 1 | husband kid utility | **ESTIMATE** | marriage + fertility |
| `alpha4` | 0.65 | kid-utility curvature | **FIX-lit** | weak ID; fix |
| `taste_hs/sc/cg` | 110/150/300 | same-edu marriage premium | **ESTIMATE** | marriage rate + assortative diag |
| `mconst1_h/w`, `mconst2_h/w` | 105/80/80/40 | off-diag marriage (gendered) | **ESTIMATE** | assortative off-diagonal |
| `preg_married/unmarried/kids` | 0/0/0 | pregnancy preference | **ESTIMATE** | fertility timing |
| `mc` (marriage cost) | 0 | — | **FIX** at 0 (or estimate) | |
| `dc_w`, `dc_h` | −200 / −350 | divorce cost | **ESTIMATE** | divorce rates |
| `t5_w/t6_w`, `t5_h/t6_h` | 500/250, 450/200 | terminal marriage/kids | **ESTIMATE** (or FIX) | end-horizon behavior |
| `t1_w..t4_w`, `t1_h..t4_h` | ~19–33 | terminal edu values | **FIX** | weak ID; fix at current |

---

## E. Shock variances → ESTIMATE

| Param | Value | Role | Decision |
|-------|------:|------|----------|
| `sigma_q` | exp(−0.598)≈0.55 | match-quality SD | **ESTIMATE** (divorce dispersion) |
| `sigma_p` | exp(−0.59)≈0.55 | pregnancy-pref SD | **ESTIMATE** (fertility dispersion) |
| `sigma_ability_w/h` | exp(−0.13)/exp(−0.17) | ability SD | **1st-stage / FIX-norm** |

---

## Proposed estimated set (structural search)

Core ~16, in priority order of objective impact:
1. `dc_w`, `dc_h` — divorce
2. `taste_hs`, `taste_sc`, `taste_cg` — marriage diagonal
3. `mconst1_h`, `mconst1_w`, `mconst2_h`, `mconst2_w` — marriage off-diagonal
4. `alpha3_w_m`, `alpha3_w_s`, `alpha3_h_m` — kid utility
5. `alpha2w0`, `alpha2w1` — wife leisure
6. `sigma_q` — match dispersion
7. `omega3` (and maybe `omega4_w`) — meeting prob

Everything else: FIX (constants) or 1st-stage (wage/offer process).

## Decisions (resolved 2026-05-26)
1. **Wage process**: FIXED from Osnat's external (auxiliary) estimates — all `beta*_w/h`, `sigma_*_wage`, `lambda*` initial values are pre-estimated; hold fixed in the structural loop.
2. **`alpha0`**: **FIX at 0.541** — this is the structurally estimated CRRA consumption parameter from the EKL paper (Eckstein-Keane-Lifshitz, p.65 table: η=0.541, SE 0.038, same across 1960/70/80 cohorts). Functional form matches: (1/η)·C^η. Also confirmed it's a scale parameter (0.541→0.45 doubled the objective), so not independently estimable anyway. Cite EKL. (Note: EKL also has a CRRA *leisure* parameter = 0.751 — current model uses linear leisure.)
3. **Terminal values t1–t4**: FIX at current (weak ID).
4. **Estimate the full ~16-param set jointly** (not phased).

## Final estimated set (~16)
`dc_w, dc_h, taste_hs, taste_sc, taste_cg, mconst1_h, mconst1_w, mconst2_h, mconst2_w, alpha3_w_m, alpha3_w_s, alpha3_h_m, alpha2w0, alpha2w1, sigma_q, omega3`

(Plus consider `preg_unmarried`, `t5/t6` if the core set leaves big residuals.)
