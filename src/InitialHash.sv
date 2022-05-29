`timescale 1ns / 1ps

module InitialHash(
    input clk,
    input [55:0] chars,
    output [55:0] pipeline_del_str,
    input [31:0] seed,
    output reg [31:0] hash
);

parameter PIPELINE_DELAY = 11;
reg [55:0] str_pipeline [0:PIPELINE_DELAY-1];

integer i;
always @ (posedge clk) begin
    str_pipeline[0] <= chars;
    for (i = 1; i < PIPELINE_DELAY; i = i + 1) begin
        str_pipeline[i] <= str_pipeline[i - 1];
    end
end

assign pipeline_del_str = str_pipeline[PIPELINE_DELAY-1];

reg [31:0] pipeline [0:7];

always @(posedge clk) begin
    pipeline[0] <= ((       seed << 5) +        seed) ^ {25'b0,           chars[ 6: 0]};
    pipeline[1] <= ((pipeline[0] << 5) + pipeline[0]) ^ {25'b0, str_pipeline[0][13: 7]};
    pipeline[2] <= ((pipeline[1] << 5) + pipeline[1]) ^ {25'b0, str_pipeline[1][20:14]};
    pipeline[3] <= ((pipeline[2] << 5) + pipeline[2]) ^ {25'b0, str_pipeline[2][27:21]};
    pipeline[4] <= ((pipeline[3] << 5) + pipeline[3]) ^ {25'b0, str_pipeline[3][34:28]};
    pipeline[5] <= ((pipeline[4] << 5) + pipeline[4]) ^ {25'b0, str_pipeline[4][41:35]};
    pipeline[6] <= ((pipeline[5] << 5) + pipeline[5]) ^ {25'b0, str_pipeline[5][48:42]};
    pipeline[7] <= ((pipeline[6] << 5) + pipeline[6]) ^ {25'b0, str_pipeline[6][55:49]};
end

assign hash = pipeline[7];

endmodule
