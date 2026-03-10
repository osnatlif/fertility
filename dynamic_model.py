# entry point for the dynamic model estimation
from time import perf_counter
import cohorts
import getopt
import sys

def usage(proc):
    print("usage: " + proc +
          "\n\t-s --static: do not calculate emax" +
          "\n\t-m --moments: display moments" +
          "\n\t-d --dump-emax: dump emax matrices into files" +
          "\n\t-c --cohort: cohort. e.g. 1970white" +
          "\n\t-v --verbose")
    exit(0)


def main():
    options = "hsvmdc"
    long_options = ["help", "static", "verbose", "moments", "dump-emax", "cohort"]
    display_moments = False
    verbose = False
    static_model = False
    dump_emax = False
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
            elif arg in ("-c", "--cohort"):
                if len(values) == 0:
                    print("'cohort' is a mandatory parameter")
                    usage(sys.argv[0])
                cohorts.cohort = values[0]
    except getopt.error as err:
        # output error, and return with an error code
        print(str(err))
        usage(sys.argv[0])

    if cohorts.cohort is None:
        print("'cohort' is a mandatory parameter")
        usage(sys.argv[0])

    # these imports mus tbe done *after* the cohorts global parameter is set
    from calculate_emax import create_married_emax
    from calculate_emax import create_single_w_emax
    from calculate_emax import create_single_h_emax
    from calculate_emax import calculate_emax
    from calculate_emax import dump_married_emax, dump_single_emax
    import forward_simulation as fs

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
            dump_married_emax("w_emax", w_emax)
            dump_married_emax("h_emax", h_emax)
            dump_single_emax("w_s_emax", w_s_emax)
            dump_single_emax("h_s_emax", h_s_emax)

    else:
        print("static model, emax not calculated")

    value = fs.forward_simulation(w_emax, h_emax, w_s_emax, h_s_emax, verbose, display_moments)
    print(value)


if __name__ == "__main__":
    main()
