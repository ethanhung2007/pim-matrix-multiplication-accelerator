module tile_mem #(
    parameter int DEPTH = 512,
    parameter int DATA_W = 16,
    parameter string FILENAME = ""
) (
    input logic clk,
    input logic [$clog2(DEPTH)-1:0] addr,
    output logic [DATA_W-1:0] rdata
);

  (* ram_style = "block" *)
  logic [DATA_W-1:0] mem[0:DEPTH-1];

  initial if (FILENAME != "") $readmemh(FILENAME, mem);

  always_ff @(posedge clk) begin
    rdata <= mem[addr];
  end

endmodule
