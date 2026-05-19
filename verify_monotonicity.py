import numpy as np
import cohorts
import sys

if len(sys.argv) < 3:
    print("usage: " + sys.argv[0] + " <school|kids|ability|age> <tolerance> [cohort]")
    exit()

cohort_name = sys.argv[3] if len(sys.argv) > 3 else "1960white"
cohorts.cohort = cohort_name
import constant_parameters as c

emax_dir = "emax_" + cohort_name + "/"

np.set_printoptions(precision=2)

# minimum period for each education level: HS starts at t=1 (age 18), SC at t=3 (age 20), CG at t=5 (age 22)
MIN_T = [1, 3, 5]  # AGE_VALUES[i] - 17

# verify an array is monotonic (skipping -inf values)
def monotonic(arr, tolerance):
    prev = float("-inf")
    for current in arr:
        if current == float("-inf"):
            continue  # skip uninitialized cells
        if current + tolerance < prev:
            return False
        prev = current
    return True

# check that only valid entries exist (skip -inf combos)
def is_valid_married(t, s1, s2):
    return t >= MIN_T[s1] and t >= MIN_T[s2]

def is_valid_single(t, s):
    return t >= MIN_T[s]


def verify_monotonicity_married(filename, dimension, tolerance):
    data = np.load(filename+".npy")
    count = 0

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for wife schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s2 in range(0, c.school_size_f):
              if t < MIN_T[s2]:
                  continue
              for k in range(0, c.kids_size_f):
                  for ability1 in range(0, c.ability_size_f):
                      for ability2 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          # only include valid school levels for this t
                                          valid = [s1 for s1 in range(c.school_size_f) if t >= MIN_T[s1]]
                                          if len(valid) < 2:
                                              continue
                                          arr = np.array([data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq] for s1 in valid])
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  print(arr, "valid_schools=", valid)
                                                  print([t, ":", s2, k, ability1, ability2, kb5, we, he, mq])
      print(f"  total violations: {count}")

      count = 0
      print("******************************************************")
      print("non monotonic array for husband schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              if t < MIN_T[s1]:
                  continue
              for k in range(0, c.kids_size_f):
                  for ability1 in range(0, c.ability_size_f):
                      for ability2 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          valid = [s2 for s2 in range(c.school_size_f) if t >= MIN_T[s2]]
                                          if len(valid) < 2:
                                              continue
                                          arr = np.array([data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq] for s2 in valid])
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  print(arr, "valid_schools=", valid)
                                                  print([t, s1, ":", k, ability1, ability2, kb5, we, he, mq])
      print(f"  total violations: {count}")

    if dimension == "kids":
      count = 0
      print("******************************************************")
      print("non monotonic array for kids in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              if t < MIN_T[s1]:
                  continue
              for s2 in range(0, c.school_size_f):
                  if t < MIN_T[s2]:
                      continue
                  for ability1 in range(0, c.ability_size_f):
                      for ability2 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          arr = np.empty(c.kids_size_f)
                                          for k in range(0, c.kids_size_f):
                                              arr[k] = data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq]
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  print(arr)
                                                  print([t, s1, s2, ":", ability1, ability2, kb5, we, he, mq])
      print(f"  total violations: {count}")

    if dimension == "ability":
      count = 0
      print("******************************************************")
      print("non monotonic array for wife ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              if t < MIN_T[s1]:
                  continue
              for s2 in range(0, c.school_size_f):
                  if t < MIN_T[s2]:
                      continue
                  for k in range(0, c.kids_size_f):
                      for ability2 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          arr = np.empty(c.ability_size_f)
                                          for ability1 in range(0, c.ability_size_f):
                                              arr[ability1] = data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq]
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  print(arr)
                                                  print([t, s1, s2, k, ":", ability2, kb5, we, he, mq])
      print(f"  total violations: {count}")

      count = 0
      print("******************************************************")
      print("non monotonic array for husband ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              if t < MIN_T[s1]:
                  continue
              for s2 in range(0, c.school_size_f):
                  if t < MIN_T[s2]:
                      continue
                  for k in range(0, c.kids_size_f):
                      for ability1 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          arr = np.empty(c.ability_size_f)
                                          for ability2 in range(0, c.ability_size_f):
                                              arr[ability2] = data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq]
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  print(arr)
                                                  print([t, s1, s2, k, ability1, ":", kb5, we, he, mq])
      print(f"  total violations: {count}")

    if dimension == "age":
      # verify emax increases with age (t) for valid education combos
      count = 0
      print("******************************************************")
      print("non monotonic array for age (t) in: " + filename)
      print("******************************************************")
      for s1 in range(0, c.school_size_f):
          for s2 in range(0, c.school_size_f):
              min_t = max(MIN_T[s1], MIN_T[s2])
              for k in range(0, c.kids_size_f):
                  for ability1 in range(0, c.ability_size_f):
                      for ability2 in range(0, c.ability_size_f):
                          for kb5 in range(0, c.kids_below_5_size_f):
                              for we in range(0, c.emp_size_f):
                                  for he in range(0, c.emp_size_f):
                                      for mq in range(0, c.match_quality_size_f):
                                          arr = np.array([data[t, s1, s2, k, ability1, ability2, kb5, we, he, mq]
                                                          for t in range(min_t, c.max_period_f)])
                                          if not monotonic(arr, tolerance):
                                              count += 1
                                              if count <= 20:
                                                  # show first few and last few values
                                                  print(f"ages {17+min_t}-{17+c.max_period_f-1}: {arr[:5]}...{arr[-3:]}")
                                                  print([s1, s2, k, ability1, ability2, kb5, we, he, mq])
      print(f"  total violations: {count}")

      # also check invalid cells are -inf or 0
      count_invalid = 0
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  if t >= MIN_T[s1] and t >= MIN_T[s2]:
                      continue  # valid cell
                  val = data[t, s1, s2, 0, 0, 0, 0, 0, 0, 0]
                  if val != 0 and val != float('-inf') and not np.isneginf(val):
                      count_invalid += 1
                      if count_invalid <= 10:
                          print(f"  invalid cell not empty: t={t} s1={s1} s2={s2} val={val}")
      print(f"  invalid cells with unexpected values: {count_invalid}")


def verify_monotonicity_single_w(filename, dimension, tolerance):
    data = np.load(filename+".npy")
    count = 0

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for k in range(0, c.kids_size_f):
              for ability in range(0, c.ability_size_f):
                  for kb5 in range(0, c.kids_below_5_size_f):
                      for we in range(0, c.emp_size_f):
                          valid = [s for s in range(c.school_size_f) if t >= MIN_T[s]]
                          if len(valid) < 2:
                              continue
                          arr = np.array([data[t, s, k, ability, kb5, we] for s in valid])
                          if not monotonic(arr, tolerance):
                              count += 1
                              if count <= 20:
                                  print(arr, "valid_schools=", valid)
                                  print([t, ":", k, ability, kb5, we])
      print(f"  total violations: {count}")

    if dimension == "kids":
      print("******************************************************")
      print("non monotonic array for kids in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              if t < MIN_T[s]:
                  continue
              for ability in range(0, c.ability_size_f):
                  for kb5 in range(0, c.kids_below_5_size_f):
                      for we in range(0, c.emp_size_f):
                          arr = np.empty(c.kids_size_f)
                          for k in range(0, c.kids_size_f):
                              arr[k] = data[t, s, k, ability, kb5, we]
                          if not monotonic(arr, tolerance):
                              count += 1
                              if count <= 20:
                                  print(arr)
                                  print([t, s, ":", ability, kb5, we])
      print(f"  total violations: {count}")

    if dimension == "ability":
      print("******************************************************")
      print("non monotonic array for ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              if t < MIN_T[s]:
                  continue
              for k in range(0, c.kids_size_f):
                  for kb5 in range(0, c.kids_below_5_size_f):
                      for we in range(0, c.emp_size_f):
                          arr = np.empty(c.ability_size_f)
                          for ability in range(0, c.ability_size_f):
                              arr[ability] = data[t, s, k, ability, kb5, we]
                          if not monotonic(arr, tolerance):
                              count += 1
                              if count <= 20:
                                  print(arr)
                                  print([t, s, k, ":", kb5, we])
      print(f"  total violations: {count}")

    if dimension == "age":
      count = 0
      print("******************************************************")
      print("non monotonic array for age (t) in: " + filename)
      print("******************************************************")
      for s in range(0, c.school_size_f):
          for k in range(0, c.kids_size_f):
              for ability in range(0, c.ability_size_f):
                  for kb5 in range(0, c.kids_below_5_size_f):
                      for we in range(0, c.emp_size_f):
                          arr = np.array([data[t, s, k, ability, kb5, we]
                                          for t in range(MIN_T[s], c.max_period_f)])
                          if not monotonic(arr, tolerance):
                              count += 1
                              if count <= 20:
                                  print(f"ages {17+MIN_T[s]}-{17+c.max_period_f-1}: {arr[:5]}...{arr[-3:]}")
                                  print([s, k, ability, kb5, we])
      print(f"  total violations: {count}")


def verify_monotonicity_single_h(filename, dimension, tolerance):
    data = np.load(filename+".npy")
    count = 0

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for ability in range(0, c.ability_size_f):
              for he in range(0, c.emp_size_f):
                  valid = [s for s in range(c.school_size_f) if t >= MIN_T[s]]
                  if len(valid) < 2:
                      continue
                  arr = np.array([data[t, s, ability, he] for s in valid])
                  if not monotonic(arr, tolerance):
                      count += 1
                      if count <= 20:
                          print(arr, "valid_schools=", valid)
                          print([t, ":", ability, he])
      print(f"  total violations: {count}")

    if dimension == "kids":
      print("single men state does not include kids - skipping")

    if dimension == "ability":
      print("******************************************************")
      print("non monotonic array for ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              if t < MIN_T[s]:
                  continue
              for he in range(0, c.emp_size_f):
                  arr = np.empty(c.ability_size_f)
                  for ability in range(0, c.ability_size_f):
                      arr[ability] = data[t, s, ability, he]
                  if not monotonic(arr, tolerance):
                      count += 1
                      if count <= 20:
                          print(arr)
                          print([t, s, ":", he])
      print(f"  total violations: {count}")

    if dimension == "age":
      count = 0
      print("******************************************************")
      print("non monotonic array for age (t) in: " + filename)
      print("******************************************************")
      for s in range(0, c.school_size_f):
          for ability in range(0, c.ability_size_f):
              for he in range(0, c.emp_size_f):
                  arr = np.array([data[t, s, ability, he]
                                  for t in range(MIN_T[s], c.max_period_f)])
                  if not monotonic(arr, tolerance):
                      count += 1
                      if count <= 20:
                          print(f"ages {17+MIN_T[s]}-{17+c.max_period_f-1}: {arr[:5]}...{arr[-3:]}")
                          print([s, ability, he])
      print(f"  total violations: {count}")


verify_monotonicity_married(emax_dir + "w_emax", sys.argv[1], int(sys.argv[2]))
verify_monotonicity_married(emax_dir + "h_emax", sys.argv[1], int(sys.argv[2]))

verify_monotonicity_single_w(emax_dir + "w_s_emax", sys.argv[1], int(sys.argv[2]))
verify_monotonicity_single_h(emax_dir + "h_s_emax", sys.argv[1], int(sys.argv[2]))
