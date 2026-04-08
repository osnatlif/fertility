# entry point for the dynamic model estimation
from time import perf_counter
import cohorts
import getopt
import sys
import numpy as np

def usage(proc):
    print("usage: " + proc +
          "\n\t-s --static: do not calculate emax" +
          "\n\t-m --moments: display moments" +
          "\n\t-d --dump-emax: dump emax matrices into files" +
          "\n\t-l --load-emax: load saved emax from .npy files (skip backward solution)" +
          "\n\t-c --cohort: cohort. e.g. 1960white, 1985white" +
          "\n\t-v --verbose")
    exit(0)


def main():
    options = "hsvmdlc:"
    long_options = ["help", "static", "verbose", "moments", "dump-emax", "load-emax", "cohort="]
    display_moments = False
    verbose = False
    static_model = False
    dump_emax = False
    load_emax = False
    try:
        args, values = getopt.getopt(sys.argv[1:], options, long_options)
        for arg, val in args:
            if arg in ("-h", "--Help"):
                usage(sys.argv[0])
            elif arg in ("-m", "--moments"):
                display_moments = True
            elif arg in ("-v", "--verbose"):
                verbose = True
            elif arg in ("-s", "--static"):
                static_model = True
            elif arg in ("-d", "--dump-emax"):
                dump_emax = True
            elif arg in ("-l", "--load-emax"):
                load_emax = True
            elif arg in ("-c", "--cohort"):
                if not val:
                    print("'cohort' is a mandatory parameter")
                    usage(sys.argv[0])
                cohorts.cohort = val
    except getopt.error as err:
        # output error, and return with an error code
        print(str(err))
        usage(sys.argv[0])

    if cohorts.cohort is None:
        print("'cohort' is a mandatory parameter")
        usage(sys.argv[0])

    # these imports must be done *after* the cohorts global parameter is set
    from calculate_emax import create_married_emax
    from calculate_emax import create_single_w_emax
    from calculate_emax import create_single_h_emax
    from calculate_emax import calculate_emax
    from calculate_emax import dump_married_emax, dump_single_w_emax, dump_single_h_emax
    import forward_simulation as fs

    emax_dir = "emax_" + cohorts.cohort

    if load_emax:
        # load previously saved emax arrays
        print("loading saved emax from " + emax_dir + "/...")
        tic = perf_counter()
        w_emax = np.load(emax_dir + "/w_emax.npy")
        h_emax = np.load(emax_dir + "/h_emax.npy")
        w_s_emax = np.load(emax_dir + "/w_s_emax.npy")
        h_s_emax = np.load(emax_dir + "/h_s_emax.npy")
        toc = perf_counter()
        print("loaded emax in %.4f (sec)" % (toc - tic))
    else:
        w_emax = create_married_emax()
        h_emax = create_married_emax()
        w_s_emax = create_single_w_emax()
        h_s_emax = create_single_h_emax()
        if not static_model:
            tic = perf_counter()
            iter_count = calculate_emax(w_emax, h_emax, w_s_emax, h_s_emax, verbose)
            toc = perf_counter()
            print("calculate emax with %d iterations took: %.4f (sec)" % (iter_count, (toc - tic)))
            if dump_emax:
                import os
                os.makedirs(emax_dir, exist_ok=True)
                np.save(emax_dir + "/w_emax.npy", w_emax)
                np.save(emax_dir + "/h_emax.npy", h_emax)
                np.save(emax_dir + "/w_s_emax.npy", w_s_emax)
                np.save(emax_dir + "/h_s_emax.npy", h_s_emax)
                print("saved emax to " + emax_dir + "/")
        else:
            print("static model, emax not calculated")

    value = fs.forward_simulation(w_emax, h_emax, w_s_emax, h_s_emax, verbose, display_moments)
    print(value)


if __name__ == "__main__":
    main()
