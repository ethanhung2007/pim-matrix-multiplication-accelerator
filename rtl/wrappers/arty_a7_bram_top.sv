import util_pkg::*;

module arty_a7_bram_top #(
    parameter int M = 8,
    parameter int N = 8,
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int NUM_TILES = 8,
    parameter int ACC_W = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic rst,
    input logic go,
    output logic done
);
  logic [DATA_W-1:0] a_mem_data[NUM_TILES-1:0];
  logic [DATA_W-1:0] b_mem_data[NUM_TILES-1:0];
  logic [$clog2(M*TILE_K*NUM_TILES)-1:0] a_mem_addr[NUM_TILES-1:0];
  logic [$clog2(N*TILE_K*NUM_TILES)-1:0] b_mem_addr[NUM_TILES-1:0];
  logic [$clog2(M * N)-1:0] c_mem_addr;
  logic [ACC_W + $clog2(NUM_TILES)-1:0] c_mem_data;
  logic c_wr_en;
  logic [ACC_W + $clog2(NUM_TILES)-1:0] c_bram [0:M*N-1];

  always_ff @(posedge clk)
      if (c_wr_en) c_bram[c_mem_addr] <= c_mem_data;

  arty_a7_top #(
      .M(M),
      .N(N),
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .NUM_TILES(NUM_TILES),
      .ACC_W(ACC_W)
  ) top_module (
      .clk(clk),
      .go(go),
      .rst(rst),
      .done(done),
      .a_mem_data(a_mem_data),
      .b_mem_data(b_mem_data),
      .a_mem_addr(a_mem_addr),
      .b_mem_addr(b_mem_addr),
      .c_mem_addr(c_mem_addr),
      .c_mem_data(c_mem_data),
      .c_wr_en(c_wr_en)
  );

  generate
    for (genvar i = 0; i < NUM_TILES; i++) begin : gen_bram
      logic [8:0] a_local;
      logic [8:0] b_local;

      assign a_local = {a_mem_addr[i][11:9], a_mem_addr[i][5:0]};
      assign b_local = b_mem_addr[i][8:0];

      tile_mem #(
          .DEPTH(M * TILE_K),
          .DATA_W(DATA_W),
          .FILENAME($sformatf("a_tile_%0d.mem", i))
      ) u_a (
          .clk  (clk),
          .addr (a_local),
          .rdata(a_mem_data[i])
      );

      tile_mem #(
          .DEPTH(N * TILE_K),
          .DATA_W(DATA_W),
          .FILENAME($sformatf("b_tile_%0d.mem", i))
      ) u_b (
          .clk  (clk),
          .addr (b_local),
          .rdata(b_mem_data[i])
      );
    end
  endgenerate
endmodule
