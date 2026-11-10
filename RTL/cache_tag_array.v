// Four-entry tag, valid and dirty array. Read is asynchronous; writes/reset
// occur on the rising clock edge. Main-memory contents are not reset by cache reset.
module cache_tag_array (
    input wire clk, reset,
    input wire [1:0] index,
    output reg [25:0] tag_out,
    output reg valid_out,
    output reg dirty_out,
    input wire write_enable,
    input wire [25:0] tag_in,
    input wire valid_in,
    input wire dirty_in
);
    reg [25:0] tags [0:3];
    reg valid [0:3];
    reg dirty [0:3];
    integer i;

    always @(*) begin
        tag_out = tags[index];
        valid_out = valid[index];
        dirty_out = dirty[index];
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1) begin
                tags[i] <= 26'd0;
                valid[i] <= 1'b0;
                dirty[i] <= 1'b0;
            end
        end else if (write_enable) begin
            tags[index] <= tag_in;
            valid[index] <= valid_in;
            dirty[index] <= dirty_in;
        end
    end
endmodule
