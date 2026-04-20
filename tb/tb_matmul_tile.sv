import util_pkg::*;

module tb_matmul_tile;

  localparam int TILE_K = 64;
  localparam int DATA_W = 16;
  localparam int ACC_W = 2 * DATA_W + $clog2(TILE_K);

  logic clk = 0, rst, start, wr_en;
  logic [DATA_W-1:0] a_wdata;
  logic [DATA_W-1:0] b_wdata;
  logic [$clog2(TILE_K)-1:0] wr_addr;
  logic [ACC_W-1:0] psum;
  logic valid;

  matmul_tile #(
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .ACC_W (ACC_W)
  ) dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .wr_en(wr_en),
      .a_wdata(a_wdata),
      .b_wdata(b_wdata),
      .wr_addr(wr_addr),
      .psum(psum),
      .valid(valid)
  );

  always #5 clk = ~clk;

  logic [DATA_W-1:0] a_vec[TILE_K];
  logic [DATA_W-1:0] b_vec[TILE_K];

  task automatic load_and_run(input logic [DATA_W-1:0] a_in[TILE_K],
                              input logic [DATA_W-1:0] b_in[TILE_K],
                              input logic [ACC_W-1:0] expected, input string label);
    @(posedge clk);
    wr_en = 1;
    for (int i = 0; i < TILE_K; i++) begin
      wr_addr = i[$clog2(TILE_K)-1:0];
      a_wdata = a_in[i];
      b_wdata = b_in[i];
      @(posedge clk);
    end
    wr_en   = 0;
    a_wdata = '0;
    b_wdata = '0;

    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    fork
      begin
        @(posedge valid);
      end
      begin
        repeat (TILE_K + 20) @(posedge clk);
        $display("FAIL [%s]: valid never asserted", label);
        $finish;
      end
    join_any
    disable fork;

    #1;
    if (psum === expected) $display("PASS [%s]: psum = %0d (expected %0d)", label, psum, expected);
    else $display("FAIL [%s]: psum = %0d, expected %0d", label, psum, expected);
  endtask

  function automatic logic [ACC_W-1:0] dot_product(input logic [DATA_W-1:0] a_in[TILE_K],
                                                   input logic [DATA_W-1:0] b_in[TILE_K]);
    logic [ACC_W-1:0] acc;
    acc = '0;
    for (int i = 0; i < TILE_K; i++) acc += a_in[i] * b_in[i];
    return acc;
  endfunction

  initial begin
    $dumpfile("tb_matmul_tile.vcd");
    $dumpvars(0, tb_matmul_tile);

    rst     = 1;
    start   = 0;
    wr_en   = 0;
    a_wdata = '0;
    b_wdata = '0;
    wr_addr = '0;
    repeat (4) @(posedge clk);
    rst = 0;
    @(posedge clk);

    for (int i = 0; i < TILE_K; i++) begin
      a_vec[i] = 1;
      b_vec[i] = 1;
    end
    load_and_run(a_vec, b_vec, dot_product(a_vec, b_vec), "all_ones");

    for (int i = 0; i < TILE_K; i++) begin
      a_vec[i] = i[DATA_W-1:0];
      b_vec[i] = 1;
    end
    load_and_run(a_vec, b_vec, dot_product(a_vec, b_vec), "ascending_ones");

    for (int i = 0; i < TILE_K; i++) begin
      a_vec[i] = $urandom_range(0, 255);
      b_vec[i] = $urandom_range(0, 255);
    end
    load_and_run(a_vec, b_vec, dot_product(a_vec, b_vec), "random");

    for (int i = 0; i < TILE_K; i++) begin
      a_vec[i] = '0;
      b_vec[i] = '0;
    end
    load_and_run(a_vec, b_vec, dot_product(a_vec, b_vec), "zeros");

    $finish;
  end

  initial begin
    #100000;
    $display("FAIL: global timeout");
    $finish;
  end

endmodule
