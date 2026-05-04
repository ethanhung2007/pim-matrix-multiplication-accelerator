import numpy as np
import os

M = 8
N = 8
TILE_K = 64
NUM_TILES = 8
DATA_W = 16
K = TILE_K * NUM_TILES

def read_matrices(filename, row, col, data_w):
    vals = []
    with open(filename, "r") as f:
        for line in f:
            vals.append(int(line.strip(), 16))
    return np.array(vals).reshape(row, col)

def write_hex(matrix, filename, data_w):
    hex_digits = data_w // 4
    with open(filename, "w") as f:
        for val in matrix.flatten():
            f.write(f"{val:0{hex_digits}x}\n")

A = read_matrices("A.hex", M, K, DATA_W)
B = read_matrices("B.hex", K, N, DATA_W)

os.makedirs("mem", exist_ok=True)

for i in range(NUM_TILES):
    a_tile = A[:, i*TILE_K:(i+1)*TILE_K]
    b_tile = B[i*TILE_K:(i+1)*TILE_K, :]

    write_hex(a_tile, f"mem/a_tile_{i}.mem", DATA_W)
    write_hex(b_tile, f"mem/b_tile_{i}.mem", DATA_W)

    

