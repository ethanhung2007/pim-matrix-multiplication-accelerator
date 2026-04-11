package util_pkg;
    parameter int DATA_W = 16;
    parameter int TILE_K = 64;
    parameter int NUM_TILES = 8;
    parameter int ACC_W = 2*DATA_W + $clog2(TILE_K);
endpackage
