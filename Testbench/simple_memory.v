// Simulation-only main memory: 256 lines x 128 bits = 4 KiB.
// Address [11:4] selects a 16-byte cache line. Contents persist across reset.
module simple_memory (
    input wire clk, reset,
    input wire mem_req, mem_we,
    input wire [31:0] mem_addr,
    input wire [127:0] mem_wdata,
    output reg mem_ready,
    output reg [127:0] mem_rdata
);
    reg [127:0] memory [0:255];
    reg busy, armed;
    reg [2:0] delay_count;
    reg saved_we;
    reg [31:0] saved_addr;
    reg [127:0] saved_wdata;
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = {32'hA0000000 + i, 32'hB0000000 + i,
                         32'hC0000000 + i, 32'hD0000000 + i};
        end
    end

    // A request is accepted once per assertion of mem_req. The cache must
    // deassert mem_req for at least one clock before issuing another command.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 1'b0;
            armed <= 1'b1;
            delay_count <= 3'd0;
            mem_ready <= 1'b0;
            mem_rdata <= 128'd0;
            saved_we <= 1'b0;
            saved_addr <= 32'd0;
            saved_wdata <= 128'd0;
        end else begin
            mem_ready <= 1'b0;

            if (!mem_req)
                armed <= 1'b1;

            if (!busy && armed && mem_req) begin
                busy <= 1'b1;
                armed <= 1'b0;
                delay_count <= 3'd3;
                saved_we <= mem_we;
                saved_addr <= mem_addr;
                saved_wdata <= mem_wdata;
            end else if (busy) begin
                if (delay_count > 1) begin
                    delay_count <= delay_count - 1'b1;
                end else begin
                    busy <= 1'b0;
                    mem_ready <= 1'b1;
                    if (saved_we)
                        memory[saved_addr[11:4]] <= saved_wdata;
                    else
                        mem_rdata <= memory[saved_addr[11:4]];
                end
            end
        end
    end
endmodule
