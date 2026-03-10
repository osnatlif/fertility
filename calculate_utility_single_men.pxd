from draw_husband cimport Husband

cpdef tuple calculate_utility_single_men(double[:,:,:,:,:,:,:,:,:] h_s_emax,
    double wage_h_part, double wage_h_full,double tmp_full_h, Husband husband, int t, double[:] u_husband_full, int back)
