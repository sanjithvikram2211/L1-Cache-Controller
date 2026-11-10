module cache_address_decoder (
    input wire [31:0] address,
    output wire [25:0] tag,
    output wire [1:0] index,
    output wire [1:0] word_offset,
    output wire [31:0] line_address
);
    // 4 lines x 4 words/line x 4 bytes/word = 64 bytes.
    assign tag = address[31:6];
    assign index = address[5:4];
    assign word_offset = address[3:2];
    assign line_address = {address[31:4], 4'b0000};
endmodule
