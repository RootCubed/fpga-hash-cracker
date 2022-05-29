`timescale 1ns / 1ps

module NSMBWHashCracker(
    input fpgaclk,
    input rx,
    output tx,
    input reset
);

wire fast_clk;
clk_wiz clk_wiz_inst(
    .clk_in(fpgaclk),
    .clk_out(fast_clk)
);

Controller #(
    .CLKS_PER_BIT(851)
) controller(
    .fpgaclk(fast_clk),
    .rx(rx),
    .tx(tx),
    .reset(reset)
);

endmodule
