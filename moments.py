import numpy as np
import constant_parameters as c
from tabulate import tabulate
from cohorts import cohort

N_EDU = c.school_size_f    # 3
N_AG = c.N_AGE_GROUPS_f    # 5
N_AGES = 38                # ages 18-55 (index 0=age18, index 37=age55)

# age group definitions: (start_age, end_age) inclusive
AGE_GROUPS = [(22, 26), (27, 31), (32, 36), (37, 41), (42, 46)]
AG_LABELS = ["22-26", "27-31", "32-36", "37-41", "42-46"]


def age_to_idx(age):
    """Convert age to annual moment index (0=age18, 37=age55)."""
    return age - 18


def aggregate_to_age_groups(annual_data):
    """Aggregate annual (N_EDU, N_AGES) data into (N_EDU, N_AG) by summing ages in each group."""
    result = np.zeros((N_EDU, N_AG))
    for ag_idx, (start, end) in enumerate(AGE_GROUPS):
        idx_start = age_to_idx(start)
        idx_end = age_to_idx(end) + 1   # exclusive
        result[:, ag_idx] = annual_data[:, idx_start:idx_end].sum(axis=1)
    return result


def aggregate_to_age_groups_3d(annual_data):
    """Aggregate annual (N_EDU, N_AGES, 3) data into (N_EDU, N_AG, 3)."""
    result = np.zeros((N_EDU, N_AG, 3))
    for ag_idx, (start, end) in enumerate(AGE_GROUPS):
        idx_start = age_to_idx(start)
        idx_end = age_to_idx(end) + 1
        result[:, ag_idx, :] = annual_data[:, idx_start:idx_end, :].sum(axis=1)
    return result


class ActualMoments:
    def __init__(self):
        # employment/wage: columns are educ, age_group, full_time, part_time, wage, welfare
        self.married_w = np.loadtxt("input/married_w" + cohort + ".txt")
        self.married_h = np.loadtxt("input/married_h" + cohort + ".txt")
        self.unmarried_w = np.loadtxt("input/unmarried_w" + cohort + ".txt")
        self.unmarried_h = np.loadtxt("input/unmarried_h" + cohort + ".txt")
        # marriage/divorce: columns are educ, age_group, married, divorce
        self.marr_divorce_w = np.loadtxt("input/marr_divorce_w" + cohort + ".txt")
        self.marr_divorce_h = np.loadtxt("input/marr_divorce_h" + cohort + ".txt")
        # fertility: columns are educ, age_group, frever, childless
        self.fertility_married = np.loadtxt("input/fertility_married" + cohort + ".txt")
        self.fertility_unmarried = np.loadtxt("input/fertility_unmarried" + cohort + ".txt")
        # assortative: 3x3 matrix (own_edu x spouse_edu), ages 42-46 only
        self.assortative_w = np.loadtxt("input/assortative_w" + cohort + ".txt")  # (3, 3)
        self.assortative_h = np.loadtxt("input/assortative_h" + cohort + ".txt")  # (3, 3)

    def get_2d(self, data, col):
        """Reshape a column from 15-row file into (N_EDU, N_AG) array."""
        return data[:, col].reshape(N_EDU, N_AG)


class Moments:
    def __init__(self):
        # All moment arrays are stored annually: (edu, age_idx) where age_idx = age - 18
        # employment: (edu, age_idx, 3) where dim 2 = [unemployed, part_time, full_time]
        self.emp_wife_married = np.zeros((N_EDU, N_AGES, 3))
        self.emp_husband_married = np.zeros((N_EDU, N_AGES, 3))
        self.emp_wife_single = np.zeros((N_EDU, N_AGES, 3))
        self.emp_husband_single = np.zeros((N_EDU, N_AGES, 3))
        # wages: (edu, age_idx)
        self.wage_wife_married = np.zeros((N_EDU, N_AGES))
        self.wage_counter_wife_married = np.zeros((N_EDU, N_AGES))
        self.wage_husband_married = np.zeros((N_EDU, N_AGES))
        self.wage_counter_husband_married = np.zeros((N_EDU, N_AGES))
        self.wage_wife_single = np.zeros((N_EDU, N_AGES))
        self.wage_counter_wife_single = np.zeros((N_EDU, N_AGES))
        self.wage_husband_single = np.zeros((N_EDU, N_AGES))
        self.wage_counter_husband_single = np.zeros((N_EDU, N_AGES))
        # marriage/divorce by gender: (edu, age_idx)
        self.marriage_w = np.zeros((N_EDU, N_AGES))
        self.divorce_w = np.zeros((N_EDU, N_AGES))
        self.marriage_h = np.zeros((N_EDU, N_AGES))
        self.divorce_h = np.zeros((N_EDU, N_AGES))
        # total count per (edu, age_idx) for denominator
        self.total_w = np.zeros((N_EDU, N_AGES))
        self.total_h = np.zeros((N_EDU, N_AGES))
        # fertility: (edu, age_idx)
        self.fertility_total_married = np.zeros((N_EDU, N_AGES))
        self.fertility_count_married = np.zeros((N_EDU, N_AGES))
        self.childless_married = np.zeros((N_EDU, N_AGES))
        self.fertility_total_unmarried = np.zeros((N_EDU, N_AGES))
        self.fertility_count_unmarried = np.zeros((N_EDU, N_AGES))
        self.childless_unmarried = np.zeros((N_EDU, N_AGES))
        # assortative: (own_edu, spouse_edu) - only for ages 42-46
        self.assortative_w = np.zeros((N_EDU, N_EDU))
        self.assortative_counter_w = np.zeros(N_EDU)
        self.assortative_h = np.zeros((N_EDU, N_EDU))
        self.assortative_counter_h = np.zeros(N_EDU)


def calculate_moments(m, display_moments):
    actual = ActualMoments()
    edu_labels = ["HS", "SC", "CG+"]

    # aggregate annual moments into age groups for comparison with actual data
    emp_wm = aggregate_to_age_groups_3d(m.emp_wife_married)
    emp_hm = aggregate_to_age_groups_3d(m.emp_husband_married)
    emp_ws = aggregate_to_age_groups_3d(m.emp_wife_single)
    emp_hs = aggregate_to_age_groups_3d(m.emp_husband_single)
    wage_wm = aggregate_to_age_groups(m.wage_wife_married)
    wage_cnt_wm = aggregate_to_age_groups(m.wage_counter_wife_married)
    wage_hm = aggregate_to_age_groups(m.wage_husband_married)
    wage_cnt_hm = aggregate_to_age_groups(m.wage_counter_husband_married)
    wage_ws = aggregate_to_age_groups(m.wage_wife_single)
    wage_cnt_ws = aggregate_to_age_groups(m.wage_counter_wife_single)
    wage_hs_ag = aggregate_to_age_groups(m.wage_husband_single)
    wage_cnt_hs = aggregate_to_age_groups(m.wage_counter_husband_single)
    marriage_w = aggregate_to_age_groups(m.marriage_w)
    divorce_w = aggregate_to_age_groups(m.divorce_w)
    marriage_h = aggregate_to_age_groups(m.marriage_h)
    divorce_h = aggregate_to_age_groups(m.divorce_h)
    total_w = aggregate_to_age_groups(m.total_w)
    total_h = aggregate_to_age_groups(m.total_h)
    fert_tot_m = aggregate_to_age_groups(m.fertility_total_married)
    fert_cnt_m = aggregate_to_age_groups(m.fertility_count_married)
    childless_m = aggregate_to_age_groups(m.childless_married)
    fert_tot_u = aggregate_to_age_groups(m.fertility_total_unmarried)
    fert_cnt_u = aggregate_to_age_groups(m.fertility_count_unmarried)
    childless_u = aggregate_to_age_groups(m.childless_unmarried)

    # ========== DIAGNOSTIC: annual data for women ==========
    print("\n===== DIAGNOSTIC: ANNUAL WOMEN (all edu levels) =====")
    print("Age  | HS:Total  HS:Marr  HS:Div  HS:Kids | SC:Total  SC:Marr  SC:Div  SC:Kids | CG:Total  CG:Marr  CG:Div  CG:Kids")
    for age in range(18, 56):
        idx = age - 18
        parts = []
        for e in range(N_EDU):
            tot = m.total_w[e, idx]
            marr = m.marriage_w[e, idx] / tot if tot > 0 else 0
            div = m.divorce_w[e, idx] / tot if tot > 0 else 0
            fert_cnt = m.fertility_count_married[e, idx] + m.fertility_count_unmarried[e, idx]
            fert_tot = m.fertility_total_married[e, idx] + m.fertility_total_unmarried[e, idx]
            kids = fert_tot / fert_cnt if fert_cnt > 0 else 0
            parts.append(f"{tot:7.0f}  {marr:6.2f}  {div:5.2f}  {kids:6.2f}")
        print(f" {age}  | {'  | '.join(parts)}")

    print("\n===== DIAGNOSTIC: ANNUAL MEN (all edu levels) =====")
    print("Age  | HS:Total  HS:Marr  HS:Div  | SC:Total  SC:Marr  SC:Div  | CG:Total  CG:Marr  CG:Div")
    for age in range(18, 56):
        idx = age - 18
        parts = []
        for e in range(N_EDU):
            tot = m.total_h[e, idx]
            marr = m.marriage_h[e, idx] / tot if tot > 0 else 0
            div = m.divorce_h[e, idx] / tot if tot > 0 else 0
            parts.append(f"{tot:7.0f}  {marr:6.2f}  {div:5.2f}")
        print(f" {age}  | {'  | '.join(parts)}")

    # ========== MARRIED WOMEN: employment + wage ==========
    print("\n===== MARRIED WOMEN =====")
    mse_wage_wife_married = 0.0
    mse_emp_wife_married = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Wage:Fit", "Wage:Act", "PT:Fit", "PT:Act", "FT:Fit", "FT:Act"]
        rows = []
        for ag in range(N_AG):
            fit_wage = wage_wm[e, ag] / wage_cnt_wm[e, ag] if wage_cnt_wm[e, ag] > 0 else 0
            married_count = marriage_w[e, ag]
            fit_part = emp_wm[e, ag, 1] / married_count if married_count > 0 else 0
            fit_full = emp_wm[e, ag, 2] / married_count if married_count > 0 else 0
            act_row = e * N_AG + ag
            act_wage = actual.married_w[act_row, 4]
            act_full = actual.married_w[act_row, 2]
            act_part = actual.married_w[act_row, 3]
            rows.append([AG_LABELS[ag], fit_wage, act_wage, fit_part, act_part, fit_full, act_full])
            mse_wage_wife_married += (fit_wage/1000 - act_wage/1000)**2
            mse_emp_wife_married += (100*fit_part - 100*act_part)**2
            mse_emp_wife_married += (100*fit_full - 100*act_full)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_wage_wife_married /= (N_EDU * N_AG)
    mse_emp_wife_married /= (N_EDU * N_AG * 2)

    # ========== MARRIED MEN: employment + wage ==========
    print("\n===== MARRIED MEN =====")
    mse_wage_husband_married = 0.0
    mse_emp_husband_married = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Wage:Fit", "Wage:Act", "PT:Fit", "PT:Act", "FT:Fit", "FT:Act"]
        rows = []
        for ag in range(N_AG):
            fit_wage = wage_hm[e, ag] / wage_cnt_hm[e, ag] if wage_cnt_hm[e, ag] > 0 else 0
            married_count = marriage_h[e, ag]
            fit_part = emp_hm[e, ag, 1] / married_count if married_count > 0 else 0
            fit_full = emp_hm[e, ag, 2] / married_count if married_count > 0 else 0
            act_row = e * N_AG + ag
            act_wage = actual.married_h[act_row, 4]
            act_full = actual.married_h[act_row, 2]
            act_part = actual.married_h[act_row, 3]
            rows.append([AG_LABELS[ag], fit_wage, act_wage, fit_part, act_part, fit_full, act_full])
            mse_wage_husband_married += (fit_wage/1000 - act_wage/1000)**2
            mse_emp_husband_married += (100*fit_part - 100*act_part)**2
            mse_emp_husband_married += (100*fit_full - 100*act_full)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_wage_husband_married /= (N_EDU * N_AG)
    mse_emp_husband_married /= (N_EDU * N_AG * 2)

    # ========== SINGLE WOMEN: employment + wage ==========
    print("\n===== SINGLE WOMEN =====")
    mse_wage_wife_single = 0.0
    mse_emp_wife_single = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Wage:Fit", "Wage:Act", "PT:Fit", "PT:Act", "FT:Fit", "FT:Act"]
        rows = []
        for ag in range(N_AG):
            fit_wage = wage_ws[e, ag] / wage_cnt_ws[e, ag] if wage_cnt_ws[e, ag] > 0 else 0
            single_count = total_w[e, ag] - marriage_w[e, ag]
            fit_part = emp_ws[e, ag, 1] / single_count if single_count > 0 else 0
            fit_full = emp_ws[e, ag, 2] / single_count if single_count > 0 else 0
            act_row = e * N_AG + ag
            act_wage = actual.unmarried_w[act_row, 4]
            act_full = actual.unmarried_w[act_row, 2]
            act_part = actual.unmarried_w[act_row, 3]
            rows.append([AG_LABELS[ag], fit_wage, act_wage, fit_part, act_part, fit_full, act_full])
            mse_wage_wife_single += (fit_wage/1000 - act_wage/1000)**2
            mse_emp_wife_single += (100*fit_part - 100*act_part)**2
            mse_emp_wife_single += (100*fit_full - 100*act_full)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_wage_wife_single /= (N_EDU * N_AG)
    mse_emp_wife_single /= (N_EDU * N_AG * 2)

    # ========== SINGLE MEN: employment + wage ==========
    print("\n===== SINGLE MEN =====")
    mse_wage_husband_single = 0.0
    mse_emp_husband_single = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Wage:Fit", "Wage:Act", "PT:Fit", "PT:Act", "FT:Fit", "FT:Act"]
        rows = []
        for ag in range(N_AG):
            fit_wage = wage_hs_ag[e, ag] / wage_cnt_hs[e, ag] if wage_cnt_hs[e, ag] > 0 else 0
            single_count = total_h[e, ag] - marriage_h[e, ag]
            fit_part = emp_hs[e, ag, 1] / single_count if single_count > 0 else 0
            fit_full = emp_hs[e, ag, 2] / single_count if single_count > 0 else 0
            act_row = e * N_AG + ag
            act_wage = actual.unmarried_h[act_row, 4]
            act_full = actual.unmarried_h[act_row, 2]
            act_part = actual.unmarried_h[act_row, 3]
            rows.append([AG_LABELS[ag], fit_wage, act_wage, fit_part, act_part, fit_full, act_full])
            mse_wage_husband_single += (fit_wage/1000 - act_wage/1000)**2
            mse_emp_husband_single += (100*fit_part - 100*act_part)**2
            mse_emp_husband_single += (100*fit_full - 100*act_full)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_wage_husband_single /= (N_EDU * N_AG)
    mse_emp_husband_single /= (N_EDU * N_AG * 2)

    # ========== MARRIAGE/DIVORCE WOMEN ==========
    print("\n===== MARRIAGE/DIVORCE WOMEN =====")
    mse_marriage_w = 0.0
    mse_divorce_w = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Marr:Fit", "Marr:Act", "Div:Fit", "Div:Act"]
        rows = []
        for ag in range(N_AG):
            total = total_w[e, ag]
            fit_marr = marriage_w[e, ag] / total if total > 0 else 0
            fit_div = divorce_w[e, ag] / total if total > 0 else 0
            act_row = e * N_AG + ag
            act_marr = actual.marr_divorce_w[act_row, 2]
            act_div = actual.marr_divorce_w[act_row, 3]
            rows.append([AG_LABELS[ag], fit_marr, act_marr, fit_div, act_div])
            mse_marriage_w += (100*fit_marr - 100*act_marr)**2
            mse_divorce_w += (100*fit_div - 100*act_div)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_marriage_w /= (N_EDU * N_AG)
    mse_divorce_w /= (N_EDU * N_AG)

    # ========== MARRIAGE/DIVORCE MEN ==========
    print("\n===== MARRIAGE/DIVORCE MEN =====")
    mse_marriage_h = 0.0
    mse_divorce_h = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Marr:Fit", "Marr:Act", "Div:Fit", "Div:Act"]
        rows = []
        for ag in range(N_AG):
            total = total_h[e, ag]
            fit_marr = marriage_h[e, ag] / total if total > 0 else 0
            fit_div = divorce_h[e, ag] / total if total > 0 else 0
            act_row = e * N_AG + ag
            act_marr = actual.marr_divorce_h[act_row, 2]
            act_div = actual.marr_divorce_h[act_row, 3]
            rows.append([AG_LABELS[ag], fit_marr, act_marr, fit_div, act_div])
            mse_marriage_h += (100*fit_marr - 100*act_marr)**2
            mse_divorce_h += (100*fit_div - 100*act_div)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_marriage_h /= (N_EDU * N_AG)
    mse_divorce_h /= (N_EDU * N_AG)

    # ========== FERTILITY MARRIED ==========
    print("\n===== FERTILITY MARRIED =====")
    mse_fertility_married = 0.0
    mse_childless_married = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Fert:Fit", "Fert:Act", "Chless:Fit", "Chless:Act"]
        rows = []
        for ag in range(N_AG):
            count = fert_cnt_m[e, ag]
            fit_frever = fert_tot_m[e, ag] / count if count > 0 else 0
            fit_childless = childless_m[e, ag] / count if count > 0 else 0
            act_row = e * N_AG + ag
            act_frever = actual.fertility_married[act_row, 2]
            act_childless = actual.fertility_married[act_row, 3]
            rows.append([AG_LABELS[ag], fit_frever, act_frever, fit_childless, act_childless])
            mse_fertility_married += (fit_frever - act_frever)**2
            mse_childless_married += (100*fit_childless - 100*act_childless)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_fertility_married /= (N_EDU * N_AG)
    mse_childless_married /= (N_EDU * N_AG)

    # ========== FERTILITY UNMARRIED ==========
    print("\n===== FERTILITY UNMARRIED =====")
    mse_fertility_unmarried = 0.0
    mse_childless_unmarried = 0.0
    for e in range(N_EDU):
        headers = ["AgeGrp", "Fert:Fit", "Fert:Act", "Chless:Fit", "Chless:Act"]
        rows = []
        for ag in range(N_AG):
            count = fert_cnt_u[e, ag]
            fit_frever = fert_tot_u[e, ag] / count if count > 0 else 0
            fit_childless = childless_u[e, ag] / count if count > 0 else 0
            act_row = e * N_AG + ag
            act_frever = actual.fertility_unmarried[act_row, 2]
            act_childless = actual.fertility_unmarried[act_row, 3]
            rows.append([AG_LABELS[ag], fit_frever, act_frever, fit_childless, act_childless])
            mse_fertility_unmarried += (fit_frever - act_frever)**2
            mse_childless_unmarried += (100*fit_childless - 100*act_childless)**2
        print(f"  Education: {edu_labels[e]}")
        print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_fertility_unmarried /= (N_EDU * N_AG)
    mse_childless_unmarried /= (N_EDU * N_AG)

    # ========== ASSORTATIVE MATING WOMEN (ages 42-46 only) ==========
    print("\n===== ASSORTATIVE MATING (WOMEN, ages 42-46) =====")
    mse_assortative_w = 0.0
    headers = ["OwnEdu", "HS:Fit", "HS:Act", "SC:Fit", "SC:Act", "CG:Fit", "CG:Act"]
    rows = []
    for e in range(N_EDU):
        total = m.assortative_counter_w[e]
        fit = m.assortative_w[e, :] / total if total > 0 else np.zeros(N_EDU)
        act = actual.assortative_w[e, :]
        rows.append([edu_labels[e], fit[0], act[0], fit[1], act[1], fit[2], act[2]])
        for s in range(N_EDU):
            mse_assortative_w += (100*fit[s] - 100*act[s])**2
    print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_assortative_w /= (N_EDU * N_EDU)

    # ========== ASSORTATIVE MATING MEN (ages 42-46 only) ==========
    print("\n===== ASSORTATIVE MATING (MEN, ages 42-46) =====")
    mse_assortative_h = 0.0
    headers = ["OwnEdu", "HS:Fit", "HS:Act", "SC:Fit", "SC:Act", "CG:Fit", "CG:Act"]
    rows = []
    for e in range(N_EDU):
        total = m.assortative_counter_h[e]
        fit = m.assortative_h[e, :] / total if total > 0 else np.zeros(N_EDU)
        act = actual.assortative_h[e, :]
        rows.append([edu_labels[e], fit[0], act[0], fit[1], act[1], fit[2], act[2]])
        for s in range(N_EDU):
            mse_assortative_h += (100*fit[s] - 100*act[s])**2
    print(tabulate(rows, headers, floatfmt=".2f", tablefmt="simple"))
    mse_assortative_h /= (N_EDU * N_EDU)

    # ========== OBJECTIVE FUNCTION ==========
    objective_function = ( mse_emp_wife_married +
                           mse_emp_husband_married +
                           mse_emp_wife_single +
                           mse_emp_husband_single +
                          mse_marriage_w + mse_divorce_w +
                          mse_marriage_h + mse_divorce_h +
                          mse_fertility_married + mse_childless_married +
                          mse_fertility_unmarried + mse_childless_unmarried +
                          mse_assortative_w + mse_assortative_h)

    print("\n===== OBJECTIVE FUNCTION =====")
    print(f"Total: {objective_function:.2f}")
    print(f"  Wage wife married:     {mse_wage_wife_married:.2f}")
    print(f"  Emp wife married:      {mse_emp_wife_married:.2f}")
    print(f"  Wage husband married:  {mse_wage_husband_married:.2f}")
    print(f"  Emp husband married:   {mse_emp_husband_married:.2f}")
    print(f"  Wage wife single:      {mse_wage_wife_single:.2f}")
    print(f"  Emp wife single:       {mse_emp_wife_single:.2f}")
    print(f"  Wage husband single:   {mse_wage_husband_single:.2f}")
    print(f"  Emp husband single:    {mse_emp_husband_single:.2f}")
    print(f"  Marriage women:        {mse_marriage_w:.2f}")
    print(f"  Divorce women:         {mse_divorce_w:.2f}")
    print(f"  Marriage men:          {mse_marriage_h:.2f}")
    print(f"  Divorce men:           {mse_divorce_h:.2f}")
    print(f"  Fertility married:     {mse_fertility_married:.2f}")
    print(f"  Childless married:     {mse_childless_married:.2f}")
    print(f"  Fertility unmarried:   {mse_fertility_unmarried:.2f}")
    print(f"  Childless unmarried:   {mse_childless_unmarried:.2f}")
    print(f"  Assortative women:     {mse_assortative_w:.2f}")
    print(f"  Assortative men:       {mse_assortative_h:.2f}")

    return objective_function
