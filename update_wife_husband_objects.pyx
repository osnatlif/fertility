cimport constant_parameters as c
from constant_parameters import single_women_full_time_index_array, single_women_part_time_index_array, single_women_pregnancy_index_array
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
            wife.age_first_child = 1
    elif wife.kids == 1:
        wife.age_first_child += 1
        if wife.preg == 1:
            wife.kids += 1
            wife.age_second_child = 1
    elif wife.kids == 2:
        wife.age_first_child += 1
        wife.age_second_child += 1
        if wife.preg == 1:
            wife.kids += 1
            wife.age_third_child = 1
    elif wife.kids == 3:
        wife.age_first_child += 1
        wife.age_second_child += 1
        wife.age_third_child += 1
    # count kids below 5
    cdef int count = 0
    if wife.age_first_child > 0 and wife.age_first_child <= 5:
        count += 1
    if wife.age_second_child > 0 and wife.age_second_child <= 5:
        count += 1
    if wife.age_third_child > 0 and wife.age_third_child <= 5:
        count += 1
    wife.kb5 = count
    assert 0 <= wife.kids <= 3, ("invalid wife.kids", wife.kids)
    assert 0 <= wife.kb5 <= 3, ("invalid wife.kb5", wife.kb5)
    assert wife.kb5 <= wife.kids, ("kb5 > kids", wife.kb5, wife.kids)


cpdef update_wife_single(Wife wife, single_women_index):
    wife.age = wife.age + 1
    if wife.married == 1:
        wife.divorce = 1  # ever divorced (stock variable, never reset)
    wife.married = 0
    # education is exogenous - schooling choice (index 6) disabled, no schooling update needed
    if single_women_index in single_women_full_time_index_array:   # choose full time employment
        wife.emp = 1
        wife.capacity = 1
    elif single_women_index in single_women_part_time_index_array:   # choose part-time employment
        wife.emp = 1
        wife.capacity = 0.5
    else:
        wife.emp = 0
        wife.capacity = 0
    if single_women_index in single_women_pregnancy_index_array:   # choose to have another child
        wife.preg = 1
    else:
        wife.preg = 0
    update_wife_kids_age(wife)   # this function follows the kid's age, and drop kids at age 18
    assert wife.married == 0
    assert wife.emp in (0, 1)
    assert wife.capacity in (0, 0.5, 1)
    assert wife.preg in (0, 1)
    return


cpdef update_husband_single(Husband husband, single_men_index):
    husband.age = husband.age + 1
    if husband.married == 1:
        husband.divorce = 1  # ever divorced (stock variable, never reset)
    husband.married = 0
    # education is exogenous - schooling choice (index 6) disabled, no schooling update needed
    if single_men_index == 2:   # choose full time employment
        husband.emp = 1
        husband.capacity = 1
    elif single_men_index == 4:   # choose part-time employment
        husband.emp = 1
        husband.capacity = 0.5
    else:
        husband.emp = 0
        husband.capacity = 0
    assert husband.married == 0
    assert husband.emp in (0, 1)
    assert husband.capacity in (0, 0.5, 1)
    return

# marriage options:# first index wife, second husband
# 0-married + women unemployed  +man unemployed     +non-pregnant
# 1-married + women unemployed  +man unemployed     +pregnant
# 2-married + women unemployed  +man employed full  +non-pregnant
# 3-married + women unemployed  +man employed full  +pregnant
# 4-married + women unemployed  +man employed part  +non-pregnant
# 5-married + women unemployed  +man employed part  +pregnant
# 6-married + women employed full   +man unemployed     +non-pregnant
# 7-married + women employed full   +man unemployed     +pregnant
# 8-married + women employed full   +man employed full  +non-pregnant
# 9-married + women employed full +man employed full  +pregnant
# 10-married + women employed full +man employed part  +non-pregnant
# 11-married + women employed full +man employed part  +pregnant
# 12-married + women employed part  +man unemployed     +non-pregnant
# 13-married + women employed part +man unemployed     +pregnant
# 14-married + women employed part +man employed full  +non-pregnant
# 15-married + women employed part +man employed full  +pregnant
# 16-married + women employed part +man employed part  +non-pregnant
# 17-married + women employed part  +man employed part  +pregnant

cpdef update_married(Husband husband, Wife wife, married_index):
    wife.age = wife.age + 1
    husband.age = husband.age + 1
    wife.married = 1
    wife.divorce = 0
    husband.married = 1
    # update employment status wife
    if married_index < 6:   # wife choose unemployment
        wife.emp = 0
        wife.capacity = 0
    elif married_index < 12: # wife choose full time job
        wife.emp = 1
        wife.capacity = 1
    elif married_index < 18:
        wife.emp = 1
        wife.capacity = 0.5
    else:
        assert()
    # update employment status husband
    if married_index in men_unemployed_index_array:    # men unemployed
        husband.emp = 0
        husband.capacity = 0
    elif married_index in men_full_index_array:    # men employed full-time
        husband.emp = 1
        husband.capacity = 1
    elif married_index in men_part_index_array:    # men employed part-time
        husband.emp = 1
        husband.capacity = 0.5
    else:
        assert ()
    # update kids and pregnancy
    if married_index in pregnancy_index_array:   # choose to have another child
        husband.kids = 0    # keep number of children only at wife's object if married
        wife.preg = 1
    else:
        husband.kids = 0
        wife.preg = 0
    update_wife_kids_age(wife)   # this function follows the kid's age, and drop kids at age 18
    assert wife.married == 1
    assert husband.married == 1
    assert wife.emp in (0, 1)
    assert wife.capacity in (0, 0.5, 1)
    assert husband.emp in (0, 1)
    assert husband.capacity in (0, 0.5, 1)
    assert husband.kids == 0, ("kids must stay on wife when married", husband.kids)
    return
