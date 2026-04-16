import util_pkg::*;

module pim_matmul_top #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int NUM_TILES = 8,
    parameter int ACC_W = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic start,
    input logic rst,
    input  logic [DATA_W-1:0] a_wdata [NUM_TILES-1:0],
    input  logic [DATA_W-1:0] b_wdata [NUM_TILES-1:0],
    output logic [ACC_W + $clog2(NUM_TILES)-1:0] fsum,
    output logic valid_out
) ;

  localparam int NUM_STAGES = $clog2(NUM_TILES);

  logic [ACC_W-1:0] psum_bus [NUM_TILES];
  logic [NUM_TILES-1:0] valid_bus;
  logic [NUM_STAGES:0] valid_shift; 

  generate
    genvar i;
    for (i = 0; i < NUM_TILES; i++) begin : gen_tiles
        matmul_tile #(
          .TILE_K(TILE_K),
          .DATA_W(DATA_W),
          .ACC_W(ACC_W)
        ) tile (
            .clk(clk),
            .rst(rst),
            .start(start),
            .a_wdata(a_wdata[i]),
            .b_wdata(b_wdata[i]),
            .psum(psum_bus[i]),
            .valid(valid_bus[i])
        );
    end
  endgenerate

  reduction_tree #(
    .TILE_K(TILE_K),
    .DATA_W(DATA_W),
    .NUM_TILES(NUM_TILES),
    .ACC_W(ACC_W)
  ) tree (
    .psums(psum_bus),
    .clk(clk),
    .fsum(fsum)
  ) ;

  always_ff @(posedge clk) begin
    if (rst) valid_shift <= '0;
    else valid_shift <= {valid_shift[NUM_STAGES-1:0], &valid_bus};
  end

  assign valid_out = valid_shift[NUM_STAGES];

endmodule
