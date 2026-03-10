#include <math.h>
#include <stdlib.h>

// return maximum value of an array among given indexes
double maxvalue_filter(double arr[], int indexes[], int ilen) {
    double max = -INFINITY;
    while (ilen > 0) {
        const double value = arr[indexes[ilen-1]];
        if (max < value) {
            max = value;
        }
        ilen--;
    }
    return max;
}

// return maximum value of an array
double maxvalue(double arr[], int len) {
    double max = -INFINITY;
    while (len > 0) {
        const double value = arr[len-1];
        if (max < value) {
            max = value;
        }
        len--;
    }
    return max;
}

// taken from: https://phoxis.org/2013/05/04/generating-random-numbers-from-normal-distribution-in-c/
// note that this implementation is *not reentrent* as it uses static variables to do the actual calculation every 2nd call
double randn (double mu, double sigma) {
  double U1, U2, W, mult;
  static double X1, X2;
  static int call = 0;

  if (call == 1)
    {
      call = !call;
      return (mu + sigma * (double) X2);
    }

  do
    {
      U1 = -1 + ((double) rand () / RAND_MAX) * 2;
      U2 = -1 + ((double) rand () / RAND_MAX) * 2;
      W = pow (U1, 2) + pow (U2, 2);
    }
  while (W >= 1 || W == 0);

  mult = sqrt ((-2 * log (W)) / W);
  X1 = U1 * mult;
  X2 = U2 * mult;

  call = !call;

  return (mu + sigma * (double) X1);
}

// return uniformly distributed values in the range [0,1]
double uniform() {
    return (double)rand() / (double)RAND_MAX;
}

// return the index of a maximum of an array
int argmax(double arr[], int len) {
    double max = -INFINITY;
    int max_index = 0;
    while (len > 0) {
        const double value = arr[len-1];
        if (max < value) {
            max = value;
            max_index = len-1;
        }
        len--;
    }
    return max_index;
}

// fill an array with the same value
void fill(double arr[], int len, double value) {
    while (len > 0) {
        arr[len-1] = value;
        len--;
    }
}
