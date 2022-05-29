`timescale 1ns / 1ps

// UART receive module
// 8 data bits, no parity bits, 1 stop bit

module UARTrx #(
    parameter CLKS_PER_BIT = 868 // default; for 100 mhz clock, 115200 baud rate
) (
    input clk,
    input rx,
    output reg datarecv = 0,
    output reg [7:0] data_out = 8'b00000000
);

reg is_receiving = 0;
reg [4:0] nth_bit = 0; // which bit is currently being read
reg [31:0] clock_counter = 0;
reg [31:0] cooldown = 0;

reg prev_rx = 0;

always @(posedge clk) begin
    datarecv <= 0;
    prev_rx <= rx;
    if (cooldown > 0) cooldown <= cooldown - 1;
    if (cooldown == 0 & !is_receiving & !rx & !prev_rx) begin
        is_receiving <= 1;
        nth_bit <= 0;
        clock_counter <= CLKS_PER_BIT / 2;
        data_out <= 0;
    end else if (is_receiving) begin
        clock_counter <= clock_counter + 1;
        if (clock_counter == CLKS_PER_BIT) begin
            clock_counter <= 0;
            if (nth_bit >= 1 & nth_bit <= 8) begin
                data_out[nth_bit - 1] <= rx;
            end
            if (nth_bit == 9) begin
                is_receiving <= 0;
                datarecv <= 1;
            end
            nth_bit <= nth_bit + 1;
        end
    end
end


endmodule
