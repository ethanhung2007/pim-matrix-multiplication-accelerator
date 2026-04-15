import util_pkg::*;

module bram #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16
) (
    input logic clk,
    input logic we,
    input logic [$clog2(TILE_K)-1:0] addr,
    input logic [DATA_W-1:0] wdata,
    output logic [DATA_W-1:0] rdata
);

  (* ram_style = "block" *) logic [DATA_W-1:0] mem[TILE_K];

  always_ff @(posedge clk) begin
    if (we) mem[addr] <= wdata;
    rdata <= mem[addr];
  end

endmodule
