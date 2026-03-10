import numpy as np
import cohorts
cohorts.cohort = "1970white"
import constant_parameters as c

np.set_printoptions(precision=2)

# verify an array is monotonic
def monotonic(arr, tolerance):
    prev = float("-inf")
    for current in arr:
        if current + tolerance < prev:
            return False
        prev = current

    return True

def verify_monotonicity_married(filename, dimension, tolerance):
    data = np.load(filename+".npy")

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for wife schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s2 in range(0, c.school_size_f):
              for e1 in range(0, c.exp_size_f):
                  for e2 in range(0, c.exp_size_f):
                      for k in range(0, c.kids_size_f):
                          for health1 in range(0, c.health_size_f):
                              for health2 in range(0, c.health_size_f):
                                  for home1 in range(0, c.home_time_size_f):
                                      for home2 in range(0, c.home_time_size_f):
                                          for ability1 in range(0, c.ability_size_f):
                                              for ability2 in range(0, c.ability_size_f):
                                                  for mother1 in range(0, c.mother_size_f):
                                                      for mother2 in range(0, c.mother_size_f):
                                                          for mother3 in range(0, c.mother_size_f):
                                                              for mother4 in range(0, c.mother_size_f):
                                                                  arr = np.empty(c.school_size_f)
                                                                  for s1 in range(0, c.school_size_f):
                                                                      arr[s1] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                  if not monotonic(arr, tolerance):
                                                                      print(arr)
                                                                      print([t, ":", s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4])

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for husband schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for e1 in range(0, c.exp_size_f):
                  for e2 in range(0, c.exp_size_f):
                      for k in range(0, c.kids_size_f):
                          for health1 in range(0, c.health_size_f):
                              for health2 in range(0, c.health_size_f):
                                  for home1 in range(0, c.home_time_size_f):
                                      for home2 in range(0, c.home_time_size_f):
                                          for ability1 in range(0, c.ability_size_f):
                                              for ability2 in range(0, c.ability_size_f):
                                                  for mother1 in range(0, c.mother_size_f):
                                                      for mother2 in range(0, c.mother_size_f):
                                                          for mother3 in range(0, c.mother_size_f):
                                                              for mother4 in range(0, c.mother_size_f):
                                                                  arr = np.empty(c.school_size_f)
                                                                  for s2 in range(0, c.school_size_f):
                                                                      arr[s2] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                  if not monotonic(arr, tolerance):
                                                                      print(arr)
                                                                      print([t, s1, ":", e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4])

    if dimension == "exp":
      print("******************************************************")
      print("non monotonic array for wife experience in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  for e2 in range(0, c.exp_size_f):
                      for k in range(0, c.kids_size_f):
                          for health1 in range(0, c.health_size_f):
                              for health2 in range(0, c.health_size_f):
                                  for home1 in range(0, c.home_time_size_f):
                                      for home2 in range(0, c.home_time_size_f):
                                          for ability1 in range(0, c.ability_size_f):
                                              for ability2 in range(0, c.ability_size_f):
                                                  for mother1 in range(0, c.mother_size_f):
                                                      for mother2 in range(0, c.mother_size_f):
                                                          for mother3 in range(0, c.mother_size_f):
                                                              for mother4 in range(0, c.mother_size_f):
                                                                  arr = np.empty(c.exp_size_f)
                                                                  for e1 in range(0, c.exp_size_f):
                                                                      arr[e1] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                  if not monotonic(arr, tolerance):
                                                                      print(arr)
                                                                      print([t, s1, s2, ":", e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4])

    if dimension == "exp":
      print("******************************************************")
      print("non monotonic array for husband experience in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  for e1 in range(0, c.exp_size_f):
                      for k in range(0, c.kids_size_f):
                          for health1 in range(0, c.health_size_f):
                              for health2 in range(0, c.health_size_f):
                                  for home1 in range(0, c.home_time_size_f):
                                      for home2 in range(0, c.home_time_size_f):
                                          for ability1 in range(0, c.ability_size_f):
                                              for ability2 in range(0, c.ability_size_f):
                                                  for mother1 in range(0, c.mother_size_f):
                                                      for mother2 in range(0, c.mother_size_f):
                                                          for mother3 in range(0, c.mother_size_f):
                                                              for mother4 in range(0, c.mother_size_f):
                                                                  arr = np.empty(c.exp_size_f)
                                                                  for e2 in range(0, c.exp_size_f):
                                                                      arr[e2] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                  if not monotonic(arr, tolerance):
                                                                      print(arr)
                                                                      print([t, s1, s2, e1, ":", k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4])

    if dimension == "kids":
      print("******************************************************")
      print("non monotonic array for kids in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  for e1 in range(0, c.exp_size_f):
                      for e2 in range(0, c.exp_size_f):
                          for health1 in range(0, c.health_size_f):
                              for health2 in range(0, c.health_size_f):
                                  for home1 in range(0, c.home_time_size_f):
                                      for home2 in range(0, c.home_time_size_f):
                                          for ability1 in range(0, c.ability_size_f):
                                              for ability2 in range(0, c.ability_size_f):
                                                  for mother1 in range(0, c.mother_size_f):
                                                      for mother2 in range(0, c.mother_size_f):
                                                          for mother3 in range(0, c.mother_size_f):
                                                              for mother4 in range(0, c.mother_size_f):
                                                                  arr = np.empty(c.kids_size_f)
                                                                  for k in range(0, c.kids_size_f):
                                                                      arr[k] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                  if not monotonic(arr, tolerance):
                                                                      print(arr)
                                                                      print([t, s1, s2, e1, e2, ":", health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4])

    if dimension == "ability":
      print("******************************************************")
      print("non monotonic array for wife ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  for e1 in range(0, c.exp_size_f):
                      for e2 in range(0, c.exp_size_f):
                        for k in range(0, c.kids_size_f):
                            for health1 in range(0, c.health_size_f):
                                for health2 in range(0, c.health_size_f):
                                    for home1 in range(0, c.home_time_size_f):
                                        for home2 in range(0, c.home_time_size_f):
                                            for ability2 in range(0, c.ability_size_f):
                                                for mother1 in range(0, c.mother_size_f):
                                                    for mother2 in range(0, c.mother_size_f):
                                                        for mother3 in range(0, c.mother_size_f):
                                                            for mother4 in range(0, c.mother_size_f):
                                                                arr = np.empty(c.ability_size_f)
                                                                for ability1 in range(0, c.ability_size_f):
                                                                    arr[ability1] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                if not monotonic(arr, tolerance):
                                                                    print(arr)
                                                                    print([t, s1, s2, e1, e2, k, health1, health2, home1, home2, ":", ability2, mother1, mother2, mother3, mother4])
    
    if dimension == "ability":
      print("******************************************************")
      print("non monotonic array for husband ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s1 in range(0, c.school_size_f):
              for s2 in range(0, c.school_size_f):
                  for e1 in range(0, c.exp_size_f):
                      for e2 in range(0, c.exp_size_f):
                        for k in range(0, c.kids_size_f):
                            for health1 in range(0, c.health_size_f):
                                for health2 in range(0, c.health_size_f):
                                    for home1 in range(0, c.home_time_size_f):
                                        for home2 in range(0, c.home_time_size_f):
                                            for ability1 in range(0, c.ability_size_f):
                                                for mother1 in range(0, c.mother_size_f):
                                                    for mother2 in range(0, c.mother_size_f):
                                                        for mother3 in range(0, c.mother_size_f):
                                                            for mother4 in range(0, c.mother_size_f):
                                                                arr = np.empty(c.ability_size_f)
                                                                for ability2 in range(0, c.ability_size_f):
                                                                    arr[ability2] = data[t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ability2, mother1, mother2, mother3, mother4]
                                                                if not monotonic(arr, tolerance):
                                                                    print(arr)
                                                                    print([t, s1, s2, e1, e2, k, health1, health2, home1, home2, ability1, ":", mother1, mother2, mother3, mother4])


def verify_monotonicity_single(filename, dimension, tolerance):
    data = np.load(filename+".npy")

    if dimension == "school":
      print("******************************************************")
      print("non monotonic array for schooling in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for e in range(0, c.exp_size_f):
              for k in range(0, c.kids_size_f):
                  for health in range(0, c.health_size_f):
                      for home in range(0, c.home_time_size_f):
                          for ability in range(0, c.ability_size_f):
                              for mother1 in range(0, c.mother_size_f):
                                  for mother2 in range(0, c.mother_size_f):
                                      arr = np.empty(c.school_size_f)
                                      for s in range(0, c.school_size_f):
                                          arr[s] = data[t, s, e, k, health, home, ability, mother1, mother2]
                                      if not monotonic(arr, tolerance):
                                          print(arr)
                                          print([t, ":", e, k, health, home, ability, mother1, mother2])


    if dimension == "exp":
      print("******************************************************")
      print("non monotonic array for wife experience in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              for k in range(0, c.kids_size_f):
                  for health in range(0, c.health_size_f):
                      for home in range(0, c.home_time_size_f):
                          for ability in range(0, c.ability_size_f):
                              for mother1 in range(0, c.mother_size_f):
                                  for mother2 in range(0, c.mother_size_f):
                                      arr = np.empty(c.exp_size_f)
                                      for e in range(0, c.exp_size_f):
                                          arr[e] = data[t, s, e, k, health, home, ability, mother1, mother2]
                                      if not monotonic(arr, tolerance):
                                          print(arr)
                                          print([t, s, ":", k, health, home, ability, mother1, mother2])

    if dimension == "kids":
      print("******************************************************")
      print("non monotonic array for kids in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              for e in range(0, c.exp_size_f):
                  for health in range(0, c.health_size_f):
                      for home in range(0, c.home_time_size_f):
                          for ability in range(0, c.ability_size_f):
                              for mother1 in range(0, c.mother_size_f):
                                  for mother2 in range(0, c.mother_size_f):
                                      arr = np.empty(c.kids_size_f)
                                      for k in range(0, c.kids_size_f):
                                          arr[k] = data[t, s, e, k, health, home, ability, mother1, mother2]
                                      if not monotonic(arr, tolerance):
                                          print(arr)
                                          print([t, s, e, ":", health, home, ability, mother1, mother2])


    if dimension == "ability":
      print("******************************************************")
      print("non monotonic array for wife ability in: " + filename)
      print("******************************************************")
      for t in range(1, c.max_period_f):
          for s in range(0, c.school_size_f):
              for e in range(0, c.exp_size_f):
                  for k in range(0, c.kids_size_f):
                      for health in range(0, c.health_size_f):
                          for home in range(0, c.home_time_size_f):
                              for mother1 in range(0, c.mother_size_f):
                                  for mother2 in range(0, c.mother_size_f):
                                      arr = np.empty(c.ability_size_f)
                                      for ability in range(0, c.ability_size_f):
                                          arr[ability] = data[t, s, e, k, health, home, ability, mother1, mother2]
                                      if not monotonic(arr, tolerance):
                                          print(arr)
                                          print([t, s, e, k, health, home, ":", mother1, mother2])
    

import sys 


if len(sys.argv) != 3:
  print("usage: " + sys.argv[0] + " <school|exp|kids|ability> <tolerance>")
  exit()

verify_monotonicity_married("w_emax", sys.argv[1], int(sys.argv[2]))
verify_monotonicity_married("h_emax", sys.argv[1], int(sys.argv[2]))

verify_monotonicity_single("w_s_emax", sys.argv[1], int(sys.argv[2]))
verify_monotonicity_single("h_s_emax", sys.argv[1], int(sys.argv[2]))

