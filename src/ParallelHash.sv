`timescale 1ns / 1ps

module ParallelHash(
    input clk,
    input reset,
    input reset_counter,
    input [31:0] seed,
    input [31:0] goal,
    output success,
    output next_initial
);

parameter CSLEN1 = 63;
reg [7:0] charset1 [0:CSLEN1-1];
parameter CSLEN2 = 64;
reg [7:0] charset2 [0:CSLEN2-1];

integer i;
initial begin
    for (i = 0; i < 26; i = i + 1) begin
        charset1[i] = "A" + i;
        charset2[i] = "A" + i;
    end
    for (i = 0; i < 26; i = i + 1) begin
        charset1[26 + i] = "a" + i;
        charset2[26 + i] = "a" + i;
    end
    for (i = 0; i < 10; i = i + 1) begin
        charset1[52 + i] = "0" + i;
        charset2[52 + i] = "0" + i;
    end
    charset1[62] = "_";
    charset2[62] = "_";
    charset2[63] = "@";
end

parameter CSDIV2 = 16;
reg [$clog2(CSDIV2):0] lastchar_counter = 0;

genvar ii, iii;
generate
    reg [CSLEN1-1:0] comp1;
    for (ii = 0; ii < CSLEN1; ii = ii + 1) begin
        wire [31:0] res_hash1;
        reg [31:0] reg_hash1_pipelined;
        wire [7:0] c1 = charset1[ii];
        SingleHash h1(seed, c1[6:0], res_hash1);
        always @(posedge clk) reg_hash1_pipelined <= res_hash1;

        reg [(CSLEN2 / CSDIV2)-1:0] comp2;
        for (iii = 0; iii < CSLEN2; iii = iii + CSDIV2) begin
            wire [31:0] res_hash2;
            reg [31:0] res_hash2_pipelined;
            reg [31:0] res_hash2_33_pipelined;
            wire [7:0] c2 = charset2[iii + lastchar_counter];
            SingleHash h2(reg_hash1_pipelined, c2[6:0], res_hash2);
            always @(posedge clk) res_hash2_pipelined <= res_hash2;
            always @(posedge clk) res_hash2_33_pipelined <= res_hash2_pipelined * 33;
            always @(posedge clk) comp2[iii / CSDIV2] <= res_hash2_33_pipelined[31:7] == goal[31:7];
        end

        always @(posedge clk) comp1[ii] <= |comp2;
    end
endgenerate

assign success = |comp1;

always @(posedge clk or posedge reset) begin
    if (reset | reset_counter) begin
        lastchar_counter <= 0;
    end else begin
        lastchar_counter <= lastchar_counter + 1;
        if (lastchar_counter == CSDIV2 - 1) begin
            lastchar_counter <= 0;
        end
    end
end

assign next_initial = (lastchar_counter == CSDIV2 - 1);

endmodule
