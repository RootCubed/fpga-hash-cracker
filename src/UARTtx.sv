`timescale 1ns / 1ps

// UART transceive module
// 8 data bits, no parity bits, 1 stop bit

module UARTtx #(
    parameter CLKS_PER_BIT = 868 // default; for 100 mhz clock, 115200 baud rate
) (
    input clk,
    input [7:0] data_in,
    input send,
    output reg tx = 1,
    output reg ready = 1
);

reg [3:0] nth_bit = 0; // which bit is currently being sent
reg [31:0] clock_counter = 0;
reg [9:0] true_data;

always @(posedge clk) begin
    if (send & ready) begin
        ready <= 0;
        nth_bit <= 0;
        clock_counter <= 0;
        true_data <= {1'b1, data_in, 1'b0};
    end
    if (!ready) begin
        clock_counter <= clock_counter + 1;
        tx <= true_data[nth_bit];
        if (clock_counter == CLKS_PER_BIT) begin
            clock_counter <= 0;
            if (nth_bit == 9) begin
                ready <= 1;
            end
            nth_bit <= nth_bit + 1;
        end
    end
end


endmodule
