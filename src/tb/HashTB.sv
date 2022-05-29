`timescale 1ns / 1ps

module HashTB(
);

reg clk_master = 0;
reg rst = 0;

parameter CLK_HZ =   100000000;
parameter BIT_RATE =   1000000;

parameter PERIOD_MASTER = 64'd1000000000 / CLK_HZ;
parameter BIT_PERIOD_NS = 64'd1000000000 / BIT_RATE;

always #(PERIOD_MASTER / 2) clk_master = ~clk_master;

initial begin
    $dumpfile("HashTB.fst");
    $dumpvars();
end

reg rx_sig = 1'b1;

task uart_rx_write;
    input [7:0] i_data;
    integer i;
    begin
        // Send Start Bit
        #(BIT_PERIOD_NS);
        rx_sig = 1'b0;

        // Send Data Byte
        for (i=0; i<8; i=i+1) begin
            #(BIT_PERIOD_NS);
            rx_sig = i_data[i];
        end

        // Send Stop Bit
        #(BIT_PERIOD_NS);
        rx_sig = 1'b1;
    end
endtask

task uart_rx_write_charset_a;
    begin
        uart_rx_write("A");
        uart_rx_write("\n");
    end
endtask

task uart_rx_write_charset_full;
    begin
        uart_rx_write("A");
        uart_rx_write("G");
        uart_rx_write("I");
        uart_rx_write("L");
        uart_rx_write("M");
        uart_rx_write("Y");
        uart_rx_write("\n");
    end
endtask

integer i;

initial begin
    #2000 rst = 1;
    #2000 rst = 0;
    uart_rx_write_charset_a();
    uart_rx_write_charset_a();
    uart_rx_write_charset_a();
    uart_rx_write_charset_a();
    uart_rx_write_charset_a();
    uart_rx_write_charset_full();
    uart_rx_write_charset_full();
    uart_rx_write_charset_full();

    // seed
    uart_rx_write(8'h04);
    uart_rx_write(8'h82);
    uart_rx_write(8'h14);
    uart_rx_write(8'h27);

    // goal
    uart_rx_write(8'h32);
    uart_rx_write(8'h6f);
    uart_rx_write(8'h4d);
    #10000
    uart_rx_write(8'h9c);
end

always #5000000 begin
    $finish;
end

wire tx;

Controller #(
    .CLKS_PER_BIT(CLK_HZ / BIT_RATE)
) soc (
    .fpgaclk(clk_master),
    .reset(rst),
    .rx(rx_sig),
    .tx(tx)
);

endmodule