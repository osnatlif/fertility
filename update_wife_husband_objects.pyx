cimport constant_parameters as c
from constant_parameters import single_women_full_time_index_array, single_women_part_time_index_array, single_women_pregnancy_index_array, single_women_welfare_index_array
from constant_parameters import men_unemployed_index_array, men_full_index_array, men_part_index_array, pregnancy_index_array
from draw_wife cimport Wife
from draw_husband cimport Husband
cimport draw_wife
cimport draw_husband
cimport value_to_index
cimport libc.math as cmath
# single options:
#            0-single + unemployed + non-pregnant
#                        1-single + unemployed + pregnant - zero for men
#            2-single + employed full  + non-pregnant
#            3-single + employed full  + pregnant   - zero for men
#            4-single + employed part + non-pregnant
#            5-single + employed part + pregnant   - zero for men
#            6-schooling: single + unemployed + non-pregnant + no children


cpdef update_wife_kids_age(Wife wife):
    if wife.kids == 0:
        wife.age_first_child = 0
        wife.age_second_child = 0
        wife.age_third_child = 0
        if wife.preg == 1:
            wife.kids = 1
    elif wife.kids == 1:
        wife.age_first_child += 1
        if wife.age_first_child > 22:
            wife.kids = 0
            wife.age_first_child = 0
        if wife.preg == 1:
            wife.kids += 1
    elif wife.kids == 2:
        wife.age_first_child += 1
        wife.age_second_child += 1
        if wife.age_first_child > 22:
            wife.kids = 1
            wife.age_first_child = wife.age_second_child
            wife.age_second_child = 0
        if wife.preg == 1:
            wife.kids += 1
    elif wife.kids == 3:
        wife.age_first_child += 1
        wife.age_second_child += 1
        wife.age_third_child += 1
        if wife.age_first_child > 22:
            wife.kids = 2
            wife.age_first_child = wife.age_second_child
            wife.age_second_child = wife.age_third_child
            wife.age_third_child = 0


cpdef update_wife_single(Wife wife, single_women_index, single_women_ar):
    wife.age = wife.age + 1
    if wife.married == 1:
        wife.divorce = 1
    wife.married = 0
    wife.home_time_ar = single_women_ar
    if single_women_index == 6:   # choose to go to school
        wife.years_of_schooling = wife.years_of_schooling + 1
        wife.schooling = value_to_index.schooly_to_index(wife.years_of_schooling)
        draw_wife.update_wife_schooling(wife)
    if single_women_index in single_women_full_time_index_array:   # choose full time employment
        wife.exp = wife.exp + 1
        wife.exp_2 = cmath.pow(wife.exp, 2)
        wife.emp = 1
        wife.capacity = 1
    elif single_women_index in single_women_part_time_index_array:   # choose part-time employment
        wife.exp = wife.exp + 0.5
        wife.exp_2 = cmath.pow(wife.exp, 2)
        wife.emp = 1
        wife.capacity = 0.5
    else:
        wife.emp = 0
        wife.capacity = 0
    if single_women_index in single_women_pregnancy_index_array:   # choose to have another child
        wife.preg = 1
    else:
        wife.preg = 0
    if single_women_index in single_women_welfare_index_array:
        wife.on_welfare = 1
        wife.welfare_periods += 1
    else:
        wife.on_welfare = 0
    update_wife_kids_age(wife)   # this function follows the kid's age, and drop kids at age 18
    return


cpdef update_husband_single(Husband husband, single_men_index, single_men_ar):
    husband.age = husband.age + 1
    if husband.married == 1:
        husband.divorce = 1
    husband.married = 0
    husband.home_time_ar = single_men_ar
    if single_men_index == 6:   # choose to go to school
        husband.years_of_schooling = husband.years_of_schooling + 1
        husband.schooling = value_to_index.schooly_to_index(husband.years_of_schooling)
        draw_husband.update_school(husband)
    if single_men_index == 2:   # choose full time employment
        husband.exp = husband.exp + 1
        husband.exp_2 = cmath.pow(husband.exp, 2)
        husband.emp = 1
        husband.capacity = 1
    elif single_men_index == 4:   # choose part-time employment
        husband.exp = husband.exp + 0.5
        husband.exp_2 = cmath.pow(husband.exp, 2)
        husband.emp = 1
        husband.capacity = 0.5
    else:
        husband.emp = 0
        husband.capacity = 0
    return

# marriage options:# first index wife, second husband
#            0-married + women unemployed  +man unemployed     +non-pregnant
#                    1-married + women unemployed  +man unemployed     +pregnant
#                    2-married + women unemployed  +man employed full  +non-pregnant
#                    3-married + women unemployed  +man employed full  +pregnant
#                    4-married + women unemployed  +man employed part  +non-pregnant
#                    5-married + women unemployed  +man employed part  +pregnant
#            6-married + women employed full   +man unemployed     +non-pregnant
#                    7-married + women employed full   +man unemployed     +pregnant
#                    8-married + women employed full   +man employed full  +non-pregnant
#                    9-married + women employed full +man employed full  +pregnant
#                    10-married + women employed full +man employed part  +non-pregnant
#                    11-married + women employed full +man employed part  +pregnant
#            12-married + women employed part  +man unemployed     +non-pregnant
#                    13-married + women employed part +man unemployed     +pregnant
#                    14-married + women employed part +man employed full  +non-pregnant
#                    15-married + women employed part +man employed full  +pregnant
#                    16-married + women employed part +man employed part  +non-pregnant
#                    17-married + women employed part  +man employed part  +pregnant

cpdef update_married(Husband husband, Wife wife, married_index, home_time_h, home_time_w, home_time_h_preg, home_time_w_preg):
    wife.age = wife.age + 1
    husband.age = husband.age + 1
    wife.married = 1
    wife.divorce = 0
    husband.married = 1
    wife.on_welfare = 0
    # update employment status wife
    if married_index < 6:   # wife choose unemployment
        wife.emp = 0
        wife.capacity = 0
    elif married_index < 12: # wife choose full time job
        wife.emp = 1
        wife.capacity = 1
        wife.exp = wife.exp + 1
        wife.exp_2 = cmath.pow(wife.exp, 2)
    elif married_index < 18:
        wife.emp = 1
        wife.capacity = 0.5
        wife.exp = wife.exp + 0.5
        wife.exp_2 = cmath.pow(wife.exp, 2)
    else:
        assert()
    # update employment status husband
    if married_index in men_unemployed_index_array:    # men unemployed
        husband.emp = 0
        husband.capacity = 0
    elif married_index in men_full_index_array:    # men employed full-time
        husband.emp = 1
        husband.capacity = 1
        husband.exp = husband.exp + 1
    elif married_index in men_part_index_array:    # men employed part-time
        husband.emp = 1
        husband.capacity = 0.5
        husband.exp = husband.exp + 0.5
    else:
        assert ()
    # update kids, home time and pregnancy
    if married_index in pregnancy_index_array:   # choose to have another child
        husband.kids = 0    # keep number of children only at wife's object if married
        wife.preg = 1
        wife.home_time_ar = home_time_w_preg
        husband.home_time_ar = home_time_h_preg
    else:
        husband.kids = 0
        wife.preg = 0
        wife.home_time_ar = home_time_w
        husband.home_time_ar = home_time_h
    update_wife_kids_age(wife)   # this function follows the kid's age, and drop kids at age 18
    return
