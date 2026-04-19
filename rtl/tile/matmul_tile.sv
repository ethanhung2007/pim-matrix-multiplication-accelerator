import util_pkg::*;

module matmul_tile #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int ACC_W  = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic rst,
    input logic start,
    input logic wr_en,
    input logic [DATA_W-1:0] a_wdata,
    input logic [DATA_W-1:0] b_wdata,
    input logic [$clog2(TILE_K)-1:0] wr_addr,
    output logic [ACC_W-1:0] psum,
    output logic valid
);

  logic [DATA_W-1:0] a_rdata;
  logic [DATA_W-1:0] b_rdata;
  logic [$clog2(TILE_K)-1:0] rd_addr;
  logic en, clr;

  tile_ctrl #(
      .TILE_K(TILE_K)
  ) ctrl_fsm (
      .clk(clk),
      .start(start),
      .rst(rst),
      .clr(clr),
      .en(en),
      .valid(valid),
      .rd_addr(rd_addr)
  );

  bram #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W)
  ) a_bram (
      .clk(clk),
      .we(wr_en),
      .wr_addr(wr_addr),
      .rd_addr(rd_addr),
      .wdata(a_wdata),
      .rdata(a_rdata)
  );

  bram #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W)
  ) b_bram (
      .clk(clk),
      .we(wr_en),
      .wr_addr(wr_addr),
      .rd_addr(rd_addr),
      .wdata(b_wdata),
      .rdata(b_rdata)
  );


  mac_unit #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .ACC_W (ACC_W)
  ) mac0 (
      .a (a_rdata),
      .b (b_rdata),
      .clk(clk),
      .rst(rst),
      .clr(clr),
      .en (en),
      .P (psum)
  );

endmodule
