# convert values to indexes on their respective grids

cpdef int ability_to_index(int ability):
    return ability

# schooly_to_index removed - education is exogenous, no years_of_schooling concept

cpdef int experience_to_index(double exp):
    # Map continuous wife experience to a grid index in {0,1,2,3}.
    # Grid values are {1, 4, 8, 12}; midpoint cuts: 2.5, 5.5, 10.5.
    if exp < 2.5:
        return 0
    elif exp < 5.5:
        return 1
    elif exp < 10.5:
        return 2
    else:
        return 3
