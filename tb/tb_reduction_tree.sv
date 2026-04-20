import util_pkg::*;

module tb_reduction_tree;

  localparam int TILE_K = 64;
  localparam int DATA_W = 16;
  localparam int NUM_TILES = 8;
  localparam int ACC_W = 2 * DATA_W + $clog2(TILE_K);
  localparam int NUM_STAGES = $clog2(NUM_TILES);
  localparam int OUT_W = ACC_W + NUM_STAGES;

  logic clk = 0;
  logic [ACC_W-1:0] psum_bus[NUM_TILES];
  logic [OUT_W-1:0] fsum;

  always #5 clk = ~clk;

  reduction_tree #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .NUM_TILES(NUM_TILES),
      .ACC_W(ACC_W)
  ) tree (
      .psums(psum_bus),
      .clk  (clk),
      .fsum (fsum)
  );

  task automatic drive_and_check(input logic [ACC_W-1:0] vals[NUM_TILES],
                                 input logic [OUT_W-1:0] expected, input string label);
    for (int i = 0; i < NUM_TILES; i++) psum_bus[i] = vals[i];
    repeat (NUM_STAGES + 1) @(posedge clk);
    #1;
    if (fsum === expected) $display("PASS [%s]: fsum = %0d", label, fsum);
    else $display("FAIL [%s]: expected %0d, got %0d", label, expected, fsum);
  endtask

  logic [ACC_W-1:0] vec[NUM_TILES];

  initial begin
    $dumpfile("tb_reduction_tree.vcd");
    $dumpvars(0, tb_reduction_tree);

    for (int i = 0; i < NUM_TILES; i++) vec[i] = '0;
    @(posedge clk);

    for (int i = 0; i < NUM_TILES; i++) vec[i] = 1;
    drive_and_check(vec, NUM_TILES, "all_ones");

    for (int i = 0; i < NUM_TILES; i++) vec[i] = i;
    drive_and_check(vec, (NUM_TILES * (NUM_TILES - 1)) / 2, "ascending");

    for (int i = 0; i < NUM_TILES; i++) vec[i] = '0;
    drive_and_check(vec, '0, "zeros");

    for (int i = 0; i < NUM_TILES; i++) vec[i] = {ACC_W{1'b1}} >> 1;
    drive_and_check(vec, NUM_TILES * ({ACC_W{1'b1}} >> 1), "large");

    $finish;
  end

  initial begin
    #10000;
    $display("FAIL: timeout");
    $finish;
  end

endmodule
