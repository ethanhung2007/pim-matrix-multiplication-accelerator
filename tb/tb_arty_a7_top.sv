import util_pkg::*;

module tb_arty_a7_top;

  localparam int M = 4;
  localparam int N = 4;
  localparam int TILE_K = 8;
  localparam int NUM_TILES = 2;
  localparam int DATA_W = 8;
  localparam int ACC_W = 2 * DATA_W + $clog2(TILE_K);
  localparam int K_TOTAL = TILE_K * NUM_TILES;
  localparam int C_W = ACC_W + $clog2(NUM_TILES);
  localparam int A_AW = $clog2(M * TILE_K * NUM_TILES);
  localparam int B_AW = $clog2(TILE_K * NUM_TILES * N);
  localparam int C_AW = $clog2(M * N);

  logic clk = 0;
  logic rst, go, done, c_wr_en;
  logic [DATA_W-1:0] a_mem_data[NUM_TILES-1:0];
  logic [DATA_W-1:0] b_mem_data[NUM_TILES-1:0];
  logic [A_AW-1:0] a_mem_addr[NUM_TILES-1:0];
  logic [B_AW-1:0] b_mem_addr[NUM_TILES-1:0];
  logic [C_AW-1:0] c_mem_addr;
  logic [C_W-1:0] c_mem_data;

  arty_a7_top #(
      .M(M),
      .N(N),
      .TILE_K(TILE_K),
      .DATA_W(DATA_W),
      .NUM_TILES(NUM_TILES),
      .ACC_W(ACC_W)
  ) dut (
      .clk(clk),
      .go(go),
      .rst(rst),
      .done(done),
      .a_mem_data(a_mem_data),
      .b_mem_data(b_mem_data),
      .a_mem_addr(a_mem_addr),
      .b_mem_addr(b_mem_addr),
      .c_mem_addr(c_mem_addr),
      .c_mem_data(c_mem_data),
      .c_wr_en(c_wr_en)
  );

  logic [DATA_W-1:0] A_mem[M*K_TOTAL];
  logic [DATA_W-1:0] B_mem[K_TOTAL*N];
  logic [C_W-1:0] C_ref[M*N];
  logic [C_W-1:0] C_dut[M*N];
  logic C_written[M*N];

  always #5 clk = ~clk;

  always_ff @(posedge clk) begin
    for (int t = 0; t < NUM_TILES; t++) begin
      a_mem_data[t] <= A_mem[a_mem_addr[t]];
      b_mem_data[t] <= B_mem[b_mem_addr[t]];
    end
  end

  always_ff @(posedge clk) begin
    if (c_wr_en) begin
      C_dut[c_mem_addr] <= c_mem_data;
      C_written[c_mem_addr] <= 1;
    end
  end

  task compute_reference();
    logic [C_W-1:0] acc;
    for (int i = 0; i < M; i++) begin
      for (int j = 0; j < N; j++) begin
        acc = '0;
        for (int k = 0; k < K_TOTAL; k++) begin
          acc = acc + A_mem[i*K_TOTAL + k] * B_mem[k*N + j];
        end
        C_ref[i*N + j] = acc;
      end
    end
  endtask

  initial begin
    int errors;
    logic timed_out;

    errors = 0;
    timed_out = 0;

    rst = 1;
    go  = 0;
    for (int t = 0; t < NUM_TILES; t++) begin
      a_mem_data[t] = '0;
      b_mem_data[t] = '0;
    end
    for (int idx = 0; idx < M*N; idx++) begin
      C_dut[idx] = '0;
      C_written[idx] = 0;
    end

    for (int i = 0; i < M*K_TOTAL; i++)
      A_mem[idx] = $urandom_range((1 << DATA_W) - 1);
    for (int i = 0; i < K_TOTAL*N; i++)
      B_mem[idx] = $urandom_range((1 << DATA_W) - 1);

    compute_reference();

    repeat (4) @(posedge clk);
    rst <= 0;
    repeat (2) @(posedge clk);

    go <= 1;
    @(posedge clk);
    go <= 0;

    fork
      begin : wait_done
        @(posedge done);
      end
      begin : timeout_block
        repeat (M*N*(TILE_K + 32) + 200) @(posedge clk);
        timed_out = 1;
      end
    join_any
    disable fork;

    @(posedge clk);

    if (timed_out) begin
      $display("FAIL: timed out waiting for done");
      $finish;
    end

    for (int idx = 0; idx < M*N; idx++) begin
      automatic int i = idx / N;
      automatic int j = idx % N;
      if (!C_written[idx]) begin
        $display("FAIL: C[%0d][%0d] (idx=%0d) was never written", i, j, idx);
        errors++;
      end else if (C_dut[idx] !== C_ref[idx]) begin
        $display("FAIL: C[%0d][%0d] expected=%0d got=%0d",
                 i, j, C_ref[idx], C_dut[idx]);
        errors++;
      end
    end

    if (errors == 0)
      $display("PASS: all %0d C entries match (M=%0d N=%0d K=%0d, NUM_TILES=%0d, TILE_K=%0d)",
               M*N, M, N, K_TOTAL, NUM_TILES, TILE_K);
    else
      $display("FAIL: %0d mismatches out of %0d", errors, M*N);

    $finish;
  end

  initial begin
    $dumpfile("tb_arty_a7_top.vcd");
    $dumpvars(0, tb_arty_a7_top);
  end

endmodule
