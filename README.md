# Processing in Memory Matrix Multiplication Accelerator

## Idea (I'm kind of just yapping to myself)

In order to reduce the primary memory bottleneck, I am attempting to implement a matrix multiplication accelerator using in memory computing or processing in memory. Although this architecture may not optimize performance for an FPGA, due to the fact that there may be some DSP blocks left unused, I think it will be an interesting learning experience for processing in memory architecture which may eventually have widespread implementations with ML applications.

## Goals

1. Create and implement this matrix multiplication accelerator
2. Test it using testbenches to ensure that it actually works
3. Run benchmarks to have a definitive understanding of the performance

## Extensions

1. Sparse Matrix Support
