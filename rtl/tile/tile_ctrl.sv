import util_pkg::*;

module tile_ctrl #(
  parameter int TILE_K = 64
)(input logic clk,
  input logic start,
  input logic rst,
  output logic clr,
  output logic en,
  output logic valid,
  output logic we) ;

typedef enum {
  IDLE,
  LOAD,
  COMPUTE,
  DONE
} state_t;

state_t current_state, next_state;
logic [$clog2(TILE_K)-1:0] counter;

always_comb begin
  next_state = current_state;
  case (current_state)
    IDLE: begin
      if (start)
        next_state = LOAD;
    end
    LOAD: begin
      if (counter == TILE_K-1)
        next_state = COMPUTE;
    end
    COMPUTE: begin
      if (counter == TILE_K-1)
        next_state = DONE;
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
  end 
  else begin
    current_state <= next_state;
    if ((current_state == IDLE && next_state == LOAD) || (current_state == LOAD && next_state == COMPUTE))
      counter <= '0;
    else
      counter <= counter + 1;
  end
end

always_comb begin
  case (current_state)
    IDLE: begin
      clr = '1;
      en = '0;
      valid = '0;
      we = '0;
    end
    LOAD: begin
      clr = '0;
      en = '0;
      valid = '0;
      we = '1;
    end
    COMPUTE: begin
      clr = '0;
      en = '1;
      valid = '0;
      we = '0;
    end
    DONE: begin
      clr = '0;
      en = '0;
      valid = '1;
      we = '0;
    end
    default: begin
      clr = '0;
      en = '0;
      valid = '0;
      we = '0;
    end
  endcase
end
  

endmodule
