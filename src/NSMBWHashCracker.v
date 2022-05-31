`timescale 1ns / 1ps

module NSMBWHashCracker(
    input fpgaclk,
    input rx,
    output tx,
    input reset
);

wire clk_slow;
clk_wiz_0 clk_wiz(
    .clk_in1(fpgaclk),
    .clk_out1(clk_slow),
    .reset(reset),
    .locked()
);

Controller #(
    .CLKS_PER_BIT(1736)
) controller(
    .fpgaclk(clk_slow),
    .rx(rx),
    .tx(tx),
    .reset(reset)
);

endmodule
