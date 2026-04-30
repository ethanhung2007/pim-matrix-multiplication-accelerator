import numpy as np
import random

M = 8
K = 512
N = 8
DATA_W = 16


def generate_matrx(row, col, data_w):
    temp_list = []
    for i in range(row):
        r = []
        for j in range(col):
            r.append(random.randint(0,2**data_w - 1))
        temp_list.append(r)
    return np.array(temp_list) 

A = generate_matrx(M, K, DATA_W)
B = generate_matrx(K, N, DATA_W)

def write_hex(matrix, filename, data_w):
    hex_digits = data_w // 4
    with open(filename, "w") as f:
        for val in matrix.flatten():
            f.write(f"{val:0{hex_digits}x}\n")

write_hex(A, "A.hex", DATA_W)
write_hex(B, "B.hex", DATA_W)
