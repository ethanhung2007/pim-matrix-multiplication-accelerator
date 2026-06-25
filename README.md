# Processing in Memory Matrix Multiplication Accelerator

## Idea

In order to reduce the primary memory bottleneck, I am attempting to implement a matrix multiplication accelerator using in-memory computing or processing in memory. Although this architecture may not optimize performance for an FPGA, due to the fact that there may be some DSP blocks left unused, I think it will be an interesting learning experience for processing in memory architecture, which may eventually have widespread implementations with ML applications. 

## Goals

1. Create and implement this matrix multiplication accelerator
2. Test it using testbenches to ensure that it actually works
3. Run benchmarks to have a definitive understanding of the performance

## Current Progress

### June 20th

Finished v1 iteration with proper testbenches + synthesis and bitstream. Although everything technically works, there are a few aspects that I would like to optimize and edit. 

1. Use more of the actual fabric. The current design uses 1% LUTs, 12% BRAM, and 3% DSP blocks. To increase the maximum throughput, more of the fabric should be used.
2. Increase efficiency. There are still many bottlenecks with data transfer and memory usage.
3. Slightly change the overall architecture. The specific FPGA I'm using has DDR3 memory. Suppose I move the level 1 memory (where the initial matrices are stored) to that, the overall CIM structure would make more sense and also be more similar to CIM accelerators that are manufactured today.

### June 22nd

Added register buffering within the MAC unit to decrease the critical path and hence increase clock frequency. Clock frequency is now 160 MHz instead of 100 MHz. (Remember to update this using Clocking Wizard to synthesize a higher clock frequency)

## Potential Extensions

1. Sparse Matrix Support
