from draw_wife cimport Wife
from draw_husband cimport Husband

cpdef update_wife_kids_age(Wife wife)

cpdef update_wife_single(Wife wife, single_women_index, single_women_ar)

cpdef update_husband_single(Husband husband, single_men_index, single_men_ar)

cpdef update_married(Husband husband, Wife wife, married_index, home_time_h, home_time_w, home_time_h_preg, home_time_w_preg)
