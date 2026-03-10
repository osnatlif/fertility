from draw_husband cimport Husband
from draw_wife cimport Wife


cpdef tuple calculate_utility_married(double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] w_emax,
    double[:, :, :, :, :, :, :, :, :, :, :, :, :, :, :, :] h_emax,
    double wage_h_part, double wage_h_full, double wage_w_part, double wage_w_full,
    double tmp_full_h, double tmp_full_w, Wife wife, Husband husband, int t, 
    double[:] u_wife, double[:] u_husband, double[:] u_wife_full, double[:] u_husband_full, int back)

