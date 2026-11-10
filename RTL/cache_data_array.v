module cache_data_array (
    input wire clk, reset,
    input wire [1:0] index, word_offset,
    output wire [31:0] word_out,
    output wire [127:0] line_out,
    input wire word_write_enable,
    input wire [31:0] word_in,
    input wire line_write_enable,
    input wire [127:0] line_in
);
    reg [31:0] data [0:15];
    wire [3:0] base;
    integer i;

    assign base = {index, 2'b00};
    assign word_out = data[base + word_offset];
    assign line_out = {data[base+3], data[base+2], data[base+1], data[base]};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1)
                data[i] <= 32'd0;
        end else if (line_write_enable) begin
            data[base]   <= line_in[31:0];
            data[base+1] <= line_in[63:32];
            data[base+2] <= line_in[95:64];
            data[base+3] <= line_in[127:96];
        end else if (word_write_enable) begin
            data[base + word_offset] <= word_in;
        end
    end
endmodule
