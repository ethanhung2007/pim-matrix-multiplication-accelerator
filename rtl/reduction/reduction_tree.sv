import util_pkg::*;

module reduction_tree #(
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int NUM_TILES = 8,
    parameter int ACC_W = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic [ACC_W-1:0] psums[NUM_TILES],
    input logic clk,
    output logic [ACC_W + $clog2(NUM_TILES)-1:0] fsum
);

  localparam int NUM_STAGES = $clog2(NUM_TILES);
  localparam int OUT_W = ACC_W + NUM_STAGES;
  logic [OUT_W-1:0] stage_data[NUM_STAGES+1][NUM_TILES];

  always_ff @(posedge clk) begin
    for (int i = 0; i < NUM_TILES; i++) begin
      stage_data[0][i] <= {{NUM_STAGES{1'b0}}, psums[i]};
    end
  end

  always_ff @(posedge clk) begin
    for (int i = 1; i < NUM_STAGES + 1; i++) begin
      for (int j = 0; j < NUM_TILES / (2 ** i); j++) begin
        stage_data[i][j] <= stage_data[i-1][2*j] + stage_data[i-1][2*j+1];
      end
    end
  end

  assign fsum = stage_data[NUM_STAGES][0];

endmodule
