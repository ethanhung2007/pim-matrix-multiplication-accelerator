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
    input logic [DATA_W-1:0] a_mem_data,
    input logic [DATA_W-1:0] b_mem_data,
    output logic wr_en,
    output logic start,
    output logic [$clog2(M * TILE_K * NUM_TILES)-1:0] a_mem_addr,
    output logic [$clog2(TILE_K * NUM_TILES * N)-1:0] b_mem_addr,
    output logic [DATA_W-1:0] a_wdata[NUM_TILES-1:0],
    output logic [DATA_W-1:0] b_wdata[NUM_TILES-1:0],
    output logic done,
    output logic [$clog2(M * N)-1:0] c_mem_addr,
    output logic [ACC_W + $clog2(NUM_TILES)-1:0] c_mem_data,
    output logic c_wr_en
);

  typedef enum logic [1:0] {
    IDLE,
    LOAD,
    COMPUTE,
    OUTPUT
  } state_t;

  state_t state, next_state;

  logic [$clog2(M)-1:0] i;
  logic [$clog2(N)-1:0] j;
  logic [$clog2(TILE_K)-1:0] load_counter;
  logic [ACC_W + $clog2(NUM_TILES)-1:0] c_out;

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
    wr_en = 0;
    start = 0;
    done = 0;
    c_wr_en = 0;
    a_mem_addr = '0;
    b_mem_addr = '0;
    c_mem_addr = '0;
    c_mem_data = '0;
    a_wdata = '{default: '0};
    b_wdata = '{default: '0};
    case (state)
      IDLE: begin
      end
      LOAD: begin
        a_mem_addr = load_counter;
        b_mem_addr = load_counter;
        a_wdata = a_mem_data;
        b_wdata = b_mem_data;
        wr_en = 1;
      end
      COMPUTE: begin
      end
      OUTPUT: begin
        c_wr_en = 1;
        c_mem_data = c_out;
        c_mem_addr = i * n + j;
      end
    endcase
  end


endmodule
