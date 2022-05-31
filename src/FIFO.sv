`timescale 1ns / 1ps

module FIFO # (
    parameter WIDTH = 56
) (
    input clk,
    input reset,
    input [WIDTH - 1:0] in_data,
    input read,
    input write,
    output empty,
    output full,
    output reg [WIDTH - 1:0] out_data
);

reg [WIDTH - 1:0] mem [0:255];
reg [7:0] rd_ptr = 0;
reg [7:0] wr_ptr = 0;

assign empty = rd_ptr == wr_ptr;
assign full = rd_ptr == wr_ptr + 1;

always @(posedge clk, posedge reset) begin
    if (read & !empty) begin
        out_data <= mem[rd_ptr];
        if (write) out_data <= in_data;
        if (!write) rd_ptr <= rd_ptr + 1;
    end
    if (write & !full) begin
        mem[wr_ptr] <= in_data;
        if (!read) wr_ptr <= wr_ptr + 1;
    end
    if (reset) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
    end
end

endmodule
