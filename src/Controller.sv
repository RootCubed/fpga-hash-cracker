`timescale 1ns / 1ps

// Main controller unit

module Controller #(
    parameter CLKS_PER_BIT = 868
) (
    input fpgaclk,
    input rx,
    output tx,
    input reset
);

typedef enum bit[3:0] {
    RECV_ALPHABET,
    RECV_GOAL,
    RECV_SEED,
    PREPARE_HASH,
    DO_HASH,
    RESET
} state_e;

state_e state = RESET;

wire recv;
wire [7:0] din;

wire tx_ready;
reg [7:0] dout;

reg [55:0] str_buf = 0;
reg [3:0] str_out_pos = 0;
reg [1:0] tx_sending_state = 0;

UARTrx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) rx_inst(
    .clk(fpgaclk),
    .rx(rx),
    .datarecv(recv),
    .data_out(din)
);

UARTtx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) tx_inst(
    .clk(fpgaclk),
    .tx(tx),
    .send(tx_sending_state == 3),
    .data_in(dout),
    .ready(tx_ready)
);

wire [55:0] fifo_out;
reg fifo_read = 0;
wire fifo_empty, fifo_full;
reg fifo_write = 0;

FIFO fifo_inst(
    .clk(fpgaclk),
    .reset(reset),
    .in_data(str_buf),
    .read(fifo_read),
    .write(fifo_write),
    .empty(fifo_empty),
    .full(fifo_full),
    .out_data(fifo_out)
);

wire [55:0] gen_str;

wire gen_done;
reg [3:0] sel_charset = -1;
reg [6:0] c_set_char = 0;
reg reset_sg = 1;
reg reset_charset = 1;
wire string_gen_clk;
StringGenerator sg(
    .clk(fpgaclk),
    .next_char(string_gen_clk),
    .reset(reset_sg),
    .reset_charset(reset_charset),
    .out_str(gen_str),
    .done(gen_done),
    .sel_charset(sel_charset),
    .c_set_char(c_set_char)
);

wire [55:0] pipeline_del_gen_str;

wire [31:0] initial_hash;
reg [31:0] pipeline_ih_hash;
reg [31:0] seed = 0;
InitialHash ih(
    .clk(fpgaclk),
    .chars(gen_str),
    .pipeline_del_str(pipeline_del_gen_str),
    .seed(seed),
    .hash(initial_hash)
);
always @(posedge fpgaclk) begin
    pipeline_ih_hash <= initial_hash;
end

wire found_collision;
reg [31:0] goal = 0;

ParallelHash ph(
    .clk(fpgaclk),
    .reset(reset),
    .reset_counter(reset_sg),
    .seed(pipeline_ih_hash),
    .goal(goal),
    .success(found_collision),
    .next_initial(string_gen_clk)
);

reg [2:0] curr_charset = 0;
reg [2:0] read_goal_pos = 0;
reg [2:0] read_seed_pos = 0;

always @(posedge fpgaclk or posedge reset) begin
    fifo_write <= 0;
    sel_charset <= -1;
    reset_sg <= 1;
    reset_charset <= 0;
    if (reset) begin
        state <= RESET;
        str_buf <= 0;
        curr_charset <= 0;
        read_goal_pos <= 0;
        read_seed_pos <= 0;
        c_set_char <= 0;
        seed <= 0;
        goal <= 0;
    end else begin
        case (state)
            RESET: begin
                // "RESET"
                str_buf <= {7'd32, 7'd32, 7'd32, 7'd84, 7'd69, 7'd83, 7'd69, 7'd82};
                fifo_write <= 1;
                curr_charset <= 0;
                read_goal_pos <= 0;
                read_seed_pos <= 0;
                reset_charset <= 1;
                state <= RECV_ALPHABET;
            end
            RECV_ALPHABET: begin
                if (recv) begin
                    if (din == 8'd10) begin
                        curr_charset <= curr_charset + 1;
                        if (curr_charset == 7) begin
                            curr_charset <= 0;
                            state <= RECV_SEED;
                        end
                    end else begin
                        sel_charset <= {1'b0, 3'd7 - curr_charset};
                        c_set_char <= din[6:0];
                    end
                end
            end
            RECV_SEED: begin
                if (recv) begin
                    case (read_seed_pos)
                        0: seed[ 7: 0] <= din;
                        1: seed[15: 8] <= din;
                        2: seed[23:16] <= din;
                        3: seed[31:24] <= din;
                    endcase
                    read_seed_pos <= read_seed_pos + 1;
                    if (read_seed_pos == 3) state <= RECV_GOAL;
                end
            end
            RECV_GOAL: begin
                if (recv) begin
                    case (read_goal_pos)
                        0: goal[ 7: 0] <= din;
                        1: goal[15: 8] <= din;
                        2: goal[23:16] <= din;
                        3: goal[31:24] <= din;
                    endcase
                    read_goal_pos <= read_goal_pos + 1;
                    if (read_goal_pos == 3) state <= PREPARE_HASH;
                end
            end
            PREPARE_HASH: begin
                reset_sg <= 0;
                // "START"
                str_buf <= {7'd32, 7'd32, 7'd32, 7'd84, 7'd82, 7'd65, 7'd84, 7'd83};
                fifo_write <= 1;
                state <= DO_HASH;
            end
            DO_HASH: begin
                reset_sg <= 0;
                if (found_collision & !fifo_full & !gen_done) begin
                    str_buf <= pipeline_del_gen_str;
                    fifo_write <= 1;
                end
                if (gen_done) begin
                    state <= RESET;
                end
            end
        endcase
    end
end

// continuously send fifo queue
always @(posedge fpgaclk) begin
    fifo_read <= 0;
    if (tx_ready & !fifo_empty & tx_sending_state == 0) begin
        fifo_read <= 1;
        str_out_pos <= 0;
        tx_sending_state <= 1;
    end
    if (tx_sending_state == 1) begin
        tx_sending_state <= 2;
    end
    if (tx_sending_state == 3) begin
        tx_sending_state <= 2;
    end
    if (tx_sending_state == 2 & tx_ready) begin
        str_out_pos <= str_out_pos + 1;
        tx_sending_state <= 3;
        case (str_out_pos)
            0: dout <= { 1'b0, fifo_out[ 6: 0] };
            1: dout <= { 1'b0, fifo_out[13: 7] };
            2: dout <= { 1'b0, fifo_out[20:14] };
            3: dout <= { 1'b0, fifo_out[27:21] };
            4: dout <= { 1'b0, fifo_out[34:28] };
            5: dout <= { 1'b0, fifo_out[41:35] };
            6: dout <= { 1'b0, fifo_out[48:42] };
            7: dout <= { 1'b0, fifo_out[55:49] };
            8: dout <= 8'hD;
            9: dout <= 8'hA;
            10: begin
                str_out_pos <= 0;
                tx_sending_state <= 0;
            end
        endcase
    end
end

endmodule
