`timescale 1ns / 1ps

module StringGenerator(
    input clk,
    input next_char,
    input reset,
    input reset_charset,
    output [55:0] out_str,
    output reg done = 0,

    input [3:0] sel_charset,
    input [6:0] c_set_char
);

reg [5:0] nums [0:7];
wire [6:0] chars [0:7];
wire [5:0] lens [0:7];

integer i = 0;
initial begin
    for (i = 0; i < 8; i = i + 1) begin
        nums[i] = 0;
    end
end

assign out_str = {
    chars[0],
    chars[1],
    chars[2],
    chars[3],
    chars[4],
    chars[5],
    chars[6],
    chars[7]
};

always @(posedge clk) begin
    if (!done & next_char) begin
        nums[0] <= nums[0] + 1;
        if (nums[0] + 1 == lens[0]) begin
            nums[0] <= 0;
            nums[1] <= nums[1] + 1;
            if (nums[1] + 1 == lens[1]) begin
                nums[1] <= 0;
                nums[2] <= nums[2] + 1;
                if (nums[2] + 1 == lens[2]) begin
                    nums[2] <= 0;
                    nums[3] <= nums[3] + 1;
                    if (nums[3] + 1 == lens[3]) begin
                        nums[3] <= 0;
                        nums[4] <= nums[4] + 1;
                        if (nums[4] + 1 == lens[4]) begin
                            nums[4] <= 0;
                            nums[5] <= nums[5] + 1;
                            if (nums[5] + 1 == lens[5]) begin
                                nums[5] <= 0;
                                nums[6] <= nums[6] + 1;
                                if (nums[6] + 1 == lens[6]) begin
                                    nums[6] <= 0;
                                    nums[7] <= nums[7] + 1;
                                    if (nums[7] + 1 == lens[7]) begin
                                        nums[7] <= 0;
                                        done <= 1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if (reset) begin
        done <= 0;
        for (i = 0; i < 8; i = i + 1) nums[i] <= 0;
    end
end

genvar j;
generate
    for (j = 0; j < 8; j = j + 1) begin
        Charset cs(
            .clk(clk),
            .reset(done | reset_charset),
            .len(lens[j]),
            .ord(nums[j]),
            .char_out(chars[j]),
            .w_en(sel_charset == j),
            .w_char(c_set_char)
        );
    end
endgenerate

endmodule
