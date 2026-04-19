import util_pkg::*;

module arty_a7_top #(
    parameter int M = 8,
    parameter int N = 8,
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int NUM_TILES = 8,
    parameter int ACC_W = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic go,
    input logic rst,
    output logic done,
    input logic [DATA_W-1:0] a_mem_data[NUM_TILES-1:0],
    input logic [DATA_W-1:0] b_mem_data[NUM_TILES-1:0],
    output logic [$clog2(M * TILE_K * NUM_TILES)-1:0] a_mem_addr[NUM_TILES-1:0],
    output logic [$clog2(TILE_K * NUM_TILES * N)-1:0] b_mem_addr[NUM_TILES-1:0],
    output logic [$clog2(M * N)-1:0] c_mem_addr,
    output logic [ACC_W + $clog2(NUM_TILES)-1:0] c_mem_data,
    output logic c_wr_en
);

  logic valid_out;
  logic [ACC_W + $clog2(NUM_TILES)-1:0] fsum;
  logic wr_en;
  logic start;
  logic [$clog2(TILE_K)-1:0] wr_addr;
  logic [DATA_W-1:0] a_wdata[NUM_TILES-1:0];
  logic [DATA_W-1:0] b_wdata[NUM_TILES-1:0];

  top_controller #(
      .M(M),
      .N(N),
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .NUM_TILES(NUM_TILES),
      .ACC_W(ACC_W)
  ) u_ctrl (
      .clk(clk),
      .rst(rst),
      .go(go),
      .valid_out(valid_out),
      .fsum(fsum),
      .wr_en(wr_en),
      .start(start),
      .wr_addr(wr_addr),
      .a_mem_data(a_mem_data),
      .b_mem_data(b_mem_data),
      .a_mem_addr(a_mem_addr),
      .b_mem_addr(b_mem_addr),
      .a_wdata(a_wdata),
      .b_wdata(b_wdata),
      .done(done),
      .c_mem_addr(c_mem_addr),
      .c_mem_data(c_mem_data),
      .c_wr_en(c_wr_en)
  );

  pim_matmul_top #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .NUM_TILES(NUM_TILES),
      .ACC_W(ACC_W)
  ) u_pim (
      .clk(clk),
      .rst(rst),
      .start(start),
      .wr_en(wr_en),
      .wr_addr(wr_addr),
      .a_wdata(a_wdata),
      .b_wdata(b_wdata),
      .fsum(fsum),
      .valid_out(valid_out)
  );

endmodule
