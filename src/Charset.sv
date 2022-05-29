`timescale 1ns / 1ps

module Charset(
    input clk,
    input reset,
    output reg [5:0] len = 0,
    input [5:0] ord,
    output reg [6:0] char_out,
    input w_en,
    input [6:0] w_char
);

reg [6:0] cset [0:63];

assign char_out = cset[ord];

always @ (posedge clk) begin
    if (w_en) begin
        cset[len] <= w_char;
        len <= len + 1;
    end
    if (reset) begin
        len <= 0;
    end
end

endmodule
