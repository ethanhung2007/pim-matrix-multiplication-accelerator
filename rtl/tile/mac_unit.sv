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
  logic [2:0] en_d, clr_d; 
  logic [DATA_W-1:0] a_r1, a_r2, b_r1, b_r2;
  logic [ACC_W-1:0] P_r;

  always_ff @(posedge clk) begin
    a_r1 <= a; a_r2 <= a_r1; b_r1 <= b; b_r2 <= b_r1;
    P_r <= a_r2 * b_r2;

    en_d[0] <= en; en_d[1] <= en_d[0]; en_d[2] <= en_d[1];
    clr_d[0] <= clr; clr_d[1] <= clr_d[0]; clr_d[2] <= clr_d[1];

    if (rst) P <= '0;
    else if (clr_d[2]) P <= '0;
    else if (en_d[2]) P <= P_r + P;
  end

endmodule
