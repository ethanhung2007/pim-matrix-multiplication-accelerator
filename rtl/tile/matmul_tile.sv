import util_pkg::*;

module matmul_tile #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int ACC_W  = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [DATA_W-1:0] a_wdata,
    input logic [DATA_W-1:0] b_wdata,
    output logic [ACC_W-1:0] psum,
    output logic valid
);

  logic [$clog2(TILE_K)-1:0] addr;
  logic [DATA_W-1:0] a_rdata;
  logic [DATA_W-1:0] b_rdata;
  logic en, clr, we;

  always_ff @(posedge clk) begin
    if (clr) addr <= '0;
    else addr <= addr + 1;
  end


  tile_ctrl #(
      .TILE_K(TILE_K)
  ) ctrl_fsm (
      .clk(clk),
      .start(start),
      .rst(rst),
      .clr(clr),
      .en(en),
      .valid(valid),
      .we(we)
  );

  bram #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W)
  ) a_bram (
      .clk(clk),
      .we(we),
      .addr(addr),
      .wdata(a_wdata),
      .rdata(a_rdata)
  );

  bram #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W)
  ) b_bram (
      .clk(clk),
      .we(we),
      .addr(addr),
      .wdata(b_wdata),
      .rdata(b_rdata)
  );


  mac_unit #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .ACC_W (ACC_W)
  ) mac0 (
      .a  (a_rdata),
      .b  (b_rdata),
      .clk(clk),
      .rst(rst),
      .clr(clr),
      .en (en),
      .P  (psum)
  );

endmodule
