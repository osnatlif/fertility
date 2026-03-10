import numpy as np
cimport constant_parameters as c


cdef double[:,:] ded_and_ex = np.loadtxt("deductions_exemptions.out")
cdef double[:,:] tax_brackets = np.loadtxt("tax_brackets.out")


# tax matrix
# -----+--------------------------------------------------------------------------------------------------------------------------------------------------+---------
#      | single                                                                                                                                           | married
# -----+-----------------------------------------+--------------------------------------------------------------------------------------------------------+---------
# year | br1 | br2 | br3 | br4 | br5 | br6 | br7 | br8 | br9 | br10 | br11 | %br1 | %br2 | %br3 | %br4 | %br5 | %br6 | %br7 | %br8 | %br9 | %br10 | %br11 | ...
# ---+--------------------------------------------------------------------------------------------------------------------------------------------------+---------

cdef int TAX_PERCENT_OFFSET = 16

cdef double calculate_tax(double reduced_income, int row_number):
    cdef double tax
    cdef double lower_bracket
    cdef double upper_bracket
    cdef double percent
    cdef int i
    tax = 0.0
    if reduced_income > 0:
        for i in range(2, 17):
            lower_bracket = tax_brackets[row_number][i-1]
            upper_bracket = tax_brackets[row_number][i]
            percent = tax_brackets[row_number][i-1+TAX_PERCENT_OFFSET]
            if reduced_income <= upper_bracket:
                tax += (reduced_income - lower_bracket)*percent
                break
            tax += (upper_bracket - lower_bracket)*percent
    return tax


# deduction matrix
# -----+-------------------------------------------------------------+--------------------------------------------+--------------------------------------------+--------
#      |                                                             | 0 kids                                     | 1 kid                                      | 2 kids
# -----+-------------------------------------------------------------+--------------------------------------------+--------------------------------------------+--------
# year | ded married | ded single | ex married | ex single | ex kids | int1% | int1 | int2% | int3% | int2 | int3 | int1% | int1 | int2% | int3% | int2 | int3 | ...
# -----+-------------------------------------------------------------+--------------------------------------------+--------------------------------------------+--------

cdef int DED_OFFSET = 6
cdef int DED_KIDS_OFFSET = 6
cdef int DED_INTERVAL1_OFFSET = DED_OFFSET + 1
cdef int DED_INTERVAL2_OFFSET = DED_OFFSET + 4
cdef int DED_INTERVAL3_OFFSET = DED_OFFSET + 5

cdef double calculate_eict(double wage, int year_row, int kids):
    cdef double eict = 0.0
    cdef int kids_offset = DED_KIDS_OFFSET*kids
    cdef int offset1 = DED_INTERVAL1_OFFSET+kids_offset
    cdef int offset2 = DED_INTERVAL2_OFFSET+kids_offset
    cdef int offset3 = DED_INTERVAL3_OFFSET+kids_offset
    if wage < ded_and_ex[year_row][offset1]:
        # first interval  credit rate
        eict = wage*ded_and_ex[year_row][offset1-1]
    elif wage < ded_and_ex[year_row][offset2]:
        # second (flat) interval - max EICT
        eict = ded_and_ex[year_row][offset2-2]
    elif wage < ded_and_ex[year_row][offset3]:
        eict = (ded_and_ex[year_row][offset3] - wage) * ded_and_ex[year_row][offset3-2]

    return eict


# similar handling for husband and wife in case of singles
cdef double gross_to_net_single(int kids, double wage, int t, int back):
    # net income - first observation for taxes is 1950. so age 17 of the 1960 cohort - will be line 27
    cdef double tax
    cdef double eict
    cdef double reduced_income
    cdef int year_row = 0
    cdef double deductions_s
    cdef double exemptions_s
    if c.cohort == 1960:
        year_row = 27 + t
    elif c.cohort == 1970:
        year_row = 37 + t
    elif c.cohort == 1980:
        year_row = 47 + t
    elif c.cohort == 1990 or c.cohort == 2000 or c.cohort == 2010:
        year_row = 57 + t
    else:
        assert False
    # the tax brackets and the deductions and exemptions starts at 1950 and ends at 2050.
    # 1960 cohort - turns 16 at 1976 row 27, 1970 cohort row 37, 1980 cohort row 47
    tax = 0.0
    deductions_s = ded_and_ex[year_row][2]
    exemptions_s = ded_and_ex[year_row][4] + ded_and_ex[year_row][5] * kids
    if wage > 0.0:
        reduced_income = wage - deductions_s - exemptions_s
        if back == 1:
            eict = 0
        else:
            eict = calculate_eict(wage, year_row, kids)
        tax = calculate_tax(reduced_income, year_row)
        return wage - tax + eict
    return 0.0


cdef double gross_to_net_married(int kids, double wage_w, double wage_h, int t, int back):
    cdef double tax = 0.0
    cdef double eict
    cdef int year_row = 0
    cdef double reduced_income
    cdef double tot_income
    cdef double deductions_m
    cdef double exemptions_m
    if c.cohort == 1960:
        year_row = 27 + t
    elif c.cohort == 1970:
        year_row = 37 + t
    elif c.cohort == 1980:
        year_row = 47 + t
    elif c.cohort == 1990 or c.cohort == 2000 or c.cohort == 2010:
        year_row = 57 + t
    else:
        assert ()
    # the tax brackets and the deductions and exemptions starts at 1950 and ends at 2050.
    # 1960 cohort - turns 16 at 1976 row 27, 1970 cohort row 37, 1980 cohort row 47
    deductions_m = ded_and_ex[year_row][1]
    exemptions_m = ded_and_ex[year_row][3] + ded_and_ex[year_row][5] * kids
    if wage_h + wage_w > 0.0:
        reduced_income = wage_h + wage_w - deductions_m - exemptions_m
        tot_income = wage_h + wage_w
        if back == 1:
            eict = 0
        else:
            eict = 0 #calculate_eict(tot_income, year_row, kids)
        tax = calculate_tax(reduced_income, year_row)
        return tot_income - tax + eict
    return 0.0
