import util_pkg::*;

module mac_unit #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int ACC_W  = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic [DATA_W-1:0] a,
    input logic [DATA_W-1:0] b,
    input logic clk,
    input logic rst,
    input logic clr,
    input logic en,
    output logic [ACC_W-1:0] P
);

  always_ff @(posedge clk) begin
    if (rst) P <= '0;
    else if (clr) P <= '0;
    else if (en) P <= a * b + P;
  end

endmodule
