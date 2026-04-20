import util_pkg::*;

module top_controller #(
    parameter int M = 8,
    parameter int N = 8,
    parameter int TILE_K = 64,
    parameter int DATA_W = 16,
    parameter int NUM_TILES = 8,
    parameter int ACC_W = 2 * DATA_W + $clog2(TILE_K)
) (
    input logic clk,
    input logic go,
    input logic rst,
    input logic valid_out,
    input logic [ACC_W + $clog2(NUM_TILES)-1:0] fsum,
    input logic [DATA_W-1:0] a_mem_data[NUM_TILES-1:0],
    input logic [DATA_W-1:0] b_mem_data[NUM_TILES-1:0],
    output logic wr_en,
    output logic start,
    output logic [$clog2(M * TILE_K * NUM_TILES)-1:0] a_mem_addr[NUM_TILES-1:0],
    output logic [$clog2(TILE_K * NUM_TILES * N)-1:0] b_mem_addr[NUM_TILES-1:0],
    output logic [$clog2(TILE_K)-1:0] wr_addr,
    output logic [DATA_W-1:0] a_wdata[NUM_TILES-1:0],
    output logic [DATA_W-1:0] b_wdata[NUM_TILES-1:0],
    output logic done,
    output logic [$clog2(M * N)-1:0] c_mem_addr,
    output logic [ACC_W + $clog2(NUM_TILES)-1:0] c_mem_data,
    output logic c_wr_en
);

  localparam int K = TILE_K * NUM_TILES;

  typedef enum logic [1:0] {
    IDLE,
    LOAD,
    COMPUTE,
    OUTPUT
  } state_t;

  state_t state, next_state;

  logic [$clog2(M)-1:0] i;
  logic [$clog2(N)-1:0] j;
  logic [$clog2(TILE_K):0] load_counter;
  logic [$clog2(TILE_K)-1:0] wr_addr_r;
  logic wr_en_r;

  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        if (go) next_state = LOAD;
      end
      LOAD: begin
        if (load_counter == TILE_K - 1) next_state = COMPUTE;
      end
      COMPUTE: begin
        if (valid_out) next_state = OUTPUT;
      end
      OUTPUT: begin
        if (i == M - 1 && j == N - 1) next_state = IDLE;
        else next_state = LOAD;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      load_counter <= 0;
      i <= '0;
      j <= '0;
    end else begin
      wr_addr_r <= load_counter;
      wr_en_r <= (state == LOAD);
      state <= next_state;
      if (state == LOAD) load_counter <= load_counter + 1;
      else load_counter <= '0;
      if (state == OUTPUT) begin
        if (j == N - 1) begin
          j <= 0;
          i <= i + 1;
        end else begin
          j <= j + 1;
        end
      end
    end
  end

  always_comb begin
    start = 0;
    done = 0;
    c_wr_en = 0;
    a_mem_addr = '{default: '0};
    b_mem_addr = '{default: '0};
    c_mem_addr = '0;
    c_mem_data = '0;
    a_wdata = '{default: '0};
    b_wdata = '{default: '0};
    wr_en = 0;
    wr_addr = '{default: '0};

    if (wr_en_r) begin
      wr_en   = wr_en_r;
      wr_addr = wr_addr_r;
      for (int t = 0; t < NUM_TILES; t++) begin
        a_wdata[t] = a_mem_data[t];
        b_wdata[t] = b_mem_data[t];
      end
    end else begin
      a_wdata = '{default: '0};
      b_wdata = '{default: '0};
    end

    case (state)
      IDLE: begin
      end
      LOAD: begin
        for (int t = 0; t < NUM_TILES; t++) begin
          a_mem_addr[t] = i * K + t * TILE_K + load_counter;
          b_mem_addr[t] = (t * TILE_K + load_counter) * N + j;
          a_wdata[t] = a_mem_data[t];
          b_wdata[t] = b_mem_data[t];
        end
        start = (load_counter == TILE_K - 1);
      end
      COMPUTE: begin
      end
      OUTPUT: begin
        c_wr_en = 1;
        c_mem_data = fsum;
        c_mem_addr = i * N + j;
        if (i == M - 1 && j == N - 1) done = 1;
      end
    endcase
  end


endmodule
