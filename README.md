# Processing in Memory Matrix Multiplication Accelerator

## Idea

In order to reduce the primary memory bottleneck, this matrix-multiplication accelerator is meant to mimic a processing-in-memory dataflow. This specific design has multiple tiles, each with its own local memory and compute unit right next to it. This architecture is not optimized for FPGAs, and probably won't outperform other matrix-multiplication architectures, but it does have promise if manufactured as an ASIC.

## Architecture Overview

This design implements a two-level memory hierarchy:
- Level-1 holds the full A and B matrices (currently on-chip BRAM, initialized via $readmemh)
- Level-0 is the small scratchpad memory in each of the tiles, holding a 64-element slice each tile needs for the current output element.

Each "load" copies a slice from Level-1 into the Level-0 memory, with "compute" performing the multiply-accumulate, eventually resulting in a partial dot product. A pipelined reduction tree then sums the partial sums into the final output element C\[i\]\[j\].

There are several dataflow optimizations after the baseline architecture was synthesized and validated. 

1. Row-stationary reuse: The top controller initially refetched each row i of A everytime before performing compute. However, the row i for A stays constant throughout each column of B. This optimization was done to decrease overall memory traffic. On the current only BRAM design this optimization does not have any latency benefits; however, decreasing traffic will have benefits when Level-1 memory moves to DDR3, as A and B  share a single memory port. 

2. Double buffering: With a single scratchpad, LOAD and COMPUTE had to be completely serialized. Since the previous optimization already keeps each row of A, only B is double-buffered. Each tile has two B banks, so the MAC unit can compute the current column from one bank while preloading the next column into the other bank, hiding the loads behind compute.

## Potential Extensions

1. Sparse Matrix Support: Skip elements that contain zero using indexing, could decrease computation time for specific matrices.
2. DDR3 Level-1 store: Moving matrices A and B to external DDR makes the design represent a realistic memory hierarchy seen in PIM accelerators. 
3. Array widening + DSP usage: Compute multiple output elements in parallel to increase DSP utilization.
