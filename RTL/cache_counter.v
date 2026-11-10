module cache_counter (
    input wire clk, reset,
    input wire hit_pulse, miss_pulse,
    output reg [31:0] hit_count, miss_count
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hit_count <= 0;
            miss_count <= 0;
        end else begin
            if (hit_pulse) hit_count <= hit_count + 1'b1;
            if (miss_pulse) miss_count <= miss_count + 1'b1;
        end
    end
endmodule
