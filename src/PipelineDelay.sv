`timescale 1ns / 1ps

module PipelineDelay (
  input clk,
  input [55:0] data_in,
  output [55:0] data_out
);

reg [55:0] mem [0:8];

integer i;
always @ (posedge clk) begin
    mem[0] <= data_in;
    for (i = 1; i < 9; i = i + 1) begin
        mem[i] <= mem[i - 1];
    end
end

assign data_out = mem[8];

endmodule