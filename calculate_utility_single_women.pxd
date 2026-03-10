from draw_wife cimport Wife

cpdef tuple calculate_utility_single_women(double[:,:,:,:,:,:,:,:,:] w_s_emax,
    double wage_w_part, double wage_w_full, double tmp_w_full, Wife wife,int t, double[:] u_wife_full, int back)

