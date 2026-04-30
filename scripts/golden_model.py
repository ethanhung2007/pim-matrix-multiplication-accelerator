import numpy as np
import math

M = 8
K = 512
N = 8
DATA_W = 16
ACC_W = 2 * DATA_W + math.ceil(math.log2(K))

def read_matrices(filename, row, col, data_w):
    vals = []
    with open(filename, "r") as f:
        for line in f:
            vals.append(int(line.strip(), 16))
    return np.array(vals).reshape(row, col)

A = read_matrices("A.hex", M, K, DATA_W)
B = read_matrices("B.hex", K, N, DATA_W)

res = A @ B
hex_digits = math.ceil(ACC_W / 4)

with open("out.hex", "w") as f:
    for val in res.flatten():
        f.write(f"{val:0{hex_digits}x}\n")

