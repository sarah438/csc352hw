/*
 * Generated using Smith's Claude Anthropic 4.5 Sonnet, transcript:
 * https://smith.campusgenai.org/share/exy-x1WE0Okg6sa1pZmEP
 *
 * Instructions:
 * ```sh
 * nvcc -o vector_ops_inefficient vector_ops_inefficient.cu
 * ./vector_ops_inefficient
 *
 * # simple/legacy profiler
 * nvprof [-o profile.nvvp] [--print-gpu-trace] ./vector_ops_inefficient
 *
 * # profile
 * nsys profile -o profile_report ./vector_ops_inefficient
 * # view
 * nsys stats profile_report.qdrep
 * # GUI version
 * nsys-ui profile_report.qdrep
 * ```
 */
#include <iostream>
#include <math.h>
#include <stdio.h>
#include <cuda_runtime.h>

// Kernel 1: Add two vectors
__global__ void vectorAdd(float *a, float *b, float *c, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    // can do this concurrently using cuda
    if (idx < n) {
        c[idx] = a[idx] + b[idx];
    }
}

// Kernel 2: Multiply vector by scalar
__global__ void vectorScale(float *c, float scale, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        c[idx] = c[idx] * scale;
    }
}

// Kernel 3: Add a constant
__global__ void vectorAddConstant(float *c, float constant, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        c[idx] = c[idx] + constant;
    }
}

int main() {
    int n = 1 << 20; // 1 million elements
    size_t bytes = n * sizeof(float);

    // Allocate host memory
    float *h_a = (float*)malloc(bytes);
    float *h_b = (float*)malloc(bytes);
    float *h_c = (float*)malloc(bytes);

    // Initialize data
    // this could be more efficient using cuda
    for (int i = 0; i < n; i++) {
        h_a[i] = 1.0f;
        h_b[i] = 2.0f;
    }

    // Allocate device memory
    float *d_a, *d_b, *d_c;
    cudaMalloc(&d_a, bytes);
    cudaMalloc(&d_b, bytes);
    cudaMalloc(&d_c, bytes);

    // INEFFICIENCY 1: Multiple small memory transfers
    printf("Running efficient version with multiple operations...\n");

    cudaStream_t stream;
    cudaStreamCreate(&stream);

    cudaMemcpyAsync(d_a, h_a, bytes, cudaMemcpyDeviceToHost, stream);
    cudaMemcpyAsync(d_b, h_b, bytes, cudaMemcpyDeviceToHost, stream);
    //cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice);
    //cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice);
    //cudaMallocHost(&h_a, bytes);
    //cudaMallocHost(&h_b, bytes);

    int blockSize = 256;
    int gridSize = (n + blockSize - 1) / blockSize;

    // INEFFICIENCY 2: Multiple kernel launches with sync overhead
    //vectorAdd<<<gridSize, blockSize>>>(d_a, d_b, d_c, n);
    //cudaDeviceSynchronize(); // Explicit sync (not always needed)

    vectorAdd<<<gridSize, blockSize, 0, stream>>>(d_a, d_b, d_c, n);
    cudaMemcpyAsync(h_c, d_c, bytes, cudaMemcpyDeviceToHost, stream);


    // INEFFICIENCY 3: Transfer back to host (unnecessary)
    //cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);
    cudaStreamSynchronize(stream);
    cudaMemcpyAsync(h_c, d_c, bytes, cudaMemcpyDeviceToHost, stream);


    // INEFFICIENCY 4: Transfer back to device
    //cudaMemcpy(d_c, h_c, bytes, cudaMemcpyHostToDevice);
    cudaMemcpyAsync(d_c, h_c, bytes, cudaMemcpyHostToDevice, stream);
    vectorScale<<<gridSize, blockSize>>>(d_c, 0.5f, n);
    //cudaDeviceSynchronize();

    // INEFFICIENCY 5: Another unnecessary transfer
    //cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);
    //cudaMemcpy(d_c, h_c, bytes, cudaMemcpyHostToDevice);
    cudaMemcpyAsync(h_c, d_c, bytes, cudaMemcpyDeviceToHost, stream);
    cudaMemcpyAsync(d_c, h_c, bytes, cudaMemcpyHostToDevice, stream);

    vectorAddConstant<<<gridSize, blockSize>>>(d_c, 10.0f, n);
    cudaDeviceSynchronize();

    // Final transfer back
    cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);

    // Verify result (expected: (1+2)*0.5 + 10 = 11.5)
    printf("Sample result: h_c[0] = %f (expected 11.5)\n", h_c[0]);
    // Cleanup
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(h_a);
    free(h_b);
    free(h_c);

    printf("Done!\n");
    return 0;
}
