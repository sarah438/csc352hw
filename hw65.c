// this code was generated with the hep of CoPilot


#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

double wall_time() {
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 1e-6;
}

void dgemm_naive(int n, double *A, double *B, double *C) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            double sum = 0.0;
            for (int k = 0; k < n; k++) {
                sum += A[i*n + k] * B[k*n + j];
            }
            C[i*n + j] = sum;
        }
    }
}

int main() {
    int n = 1024;
    size_t bytes = n * n * sizeof(double);

    double *A = (double*) malloc(bytes);
    double *B = (double*) malloc(bytes);
    double *C = (double*) malloc(bytes);

    for (int i = 0; i < n*n; i++) {
        A[i] = drand48();
        B[i] = drand48();
    }

    double t0 = wall_time();
    dgemm_naive(n, A, B, C);
    double t1 = wall_time();

    double flops = 2.0 * n * n * n;
    double gflops = flops / (t1 - t0) / 1e9;

    printf("Naive DGEMM: %.3f seconds, %.3f GFLOP/s\n", t1 - t0, gflops);

    free(A); free(B); free(C);
    return 0;
}
