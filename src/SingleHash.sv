`timescale 1ns / 1ps

module SingleHash(
    input [31:0] seed,
    input [6:0] c,
    output [31:0] hash
);

assign hash = ((seed << 5) + seed) ^ {25'b0, c};

endmodule