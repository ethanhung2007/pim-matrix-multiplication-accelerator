import util_pkg::*;

module tile_ctrl #(
    parameter int TILE_K = 64
) (
    input logic clk,
    input logic start,
    input logic rst,
    output logic clr,
    output logic en,
    output logic valid,
    output logic [$clog2(TILE_K)-1:0] rd_addr
);

  typedef enum logic [2:0] {
    IDLE,
    COMPUTE,
    DRAIN,
    DONE
  } state_t;

  state_t current_state, next_state;
  logic [$clog2(TILE_K):0] counter;
  logic [1:0] drain_counter;

  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (start) next_state = COMPUTE;
      end
      COMPUTE: begin
        if (counter == TILE_K) next_state = DRAIN;
      end
      DRAIN: begin
        if (drain_counter == 2'd2) next_state = DONE;
      end
      DONE: begin
        next_state = IDLE;
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      current_state <= IDLE;
      counter <= 0;
      drain_counter <= '0;
    end else begin
      current_state <= next_state;
      if (current_state == COMPUTE) counter <= counter + 1;
      else counter <= '0;
      if (current_state == DRAIN) drain_counter <= drain_counter + 1;
      else drain_counter <= '0;
    end
  end

  always_comb begin
    rd_addr = counter[$clog2(TILE_K)-1:0];
    case (current_state)
      IDLE: begin
        clr = '1;
        en = '0;
        valid = '0;
      end
      COMPUTE: begin
        clr = '0;
        en = (counter != '0);
        valid = '0;
      end
      DRAIN: begin
        clr = '0;
        en = '0; 
        valid = '0;
      end
      DONE: begin
        clr = '0;
        en = '0;
        valid = '1;
      end
      default: begin
        clr = '0;
        en = '0;
        valid = '0;
      end
    endcase
  end


endmodule
