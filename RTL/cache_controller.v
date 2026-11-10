module cache_controller (
    input wire clk, reset,
    input wire cpu_req, cpu_we,
    input wire [31:0] cpu_addr, cpu_wdata,
    output reg cpu_ready,
    output reg [31:0] cpu_rdata,

    output reg mem_req, mem_we,
    output reg [31:0] mem_addr,
    output reg [127:0] mem_wdata,
    input wire mem_ready,
    input wire [127:0] mem_rdata,

    output reg [1:0] tag_index,
    input wire [25:0] stored_tag,
    input wire stored_valid, stored_dirty,
    output reg tag_write_enable,
    output reg [25:0] tag_write_data,
    output reg tag_valid_in, tag_dirty_in,

    output reg [1:0] data_index, data_word_offset,
    input wire [31:0] cache_word,
    input wire [127:0] cache_line,
    output reg word_write_enable,
    output reg [31:0] word_write_data,
    output reg line_write_enable,
    output reg [127:0] line_write_data,

    input wire [25:0] decoded_tag,
    input wire [1:0] decoded_index, decoded_word_offset,
    input wire [31:0] decoded_line_address,
    output reg hit_pulse, miss_pulse,
    output reg [3:0] state_debug
);
    localparam IDLE        = 4'd0,
               LOOKUP      = 4'd1,
               WB_REQ      = 4'd2,
               WB_WAIT     = 4'd3,
               WB_GAP      = 4'd4,
               REFILL_REQ  = 4'd5,
               REFILL_WAIT = 4'd6,
               REPLAY      = 4'd7;

    reg [3:0] state;
    wire [3:0] next_state;

    reg [31:0] request_addr, request_wdata;
    reg request_we;
    reg [25:0] request_tag;
    reg [1:0] request_index, request_word_offset;
    reg [31:0] request_line_address;

    reg request_armed;
    wire accepted_req = cpu_req && request_armed;

    reg miss_already_counted;
    wire cache_hit = stored_valid && (stored_tag == request_tag);

    cache_fsm fsm (
        .state(state),
        .request_valid(accepted_req),
        .hit(cache_hit),
        .valid(stored_valid),
        .dirty(stored_dirty),
        .mem_ready(mem_ready),
        .next_state(next_state)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            request_addr <= 32'd0;
            request_wdata <= 32'd0;
            request_we <= 1'b0;
            request_tag <= 26'd0;
            request_index <= 2'd0;
            request_word_offset <= 2'd0;
            request_line_address <= 32'd0;
            request_armed <= 1'b1;
            miss_already_counted <= 1'b0;
        end else begin
            state <= next_state;

            if (!cpu_req)
                request_armed <= 1'b1;

            if (state == IDLE && accepted_req) begin
                request_armed <= 1'b0;
                request_addr <= cpu_addr;
                request_wdata <= cpu_wdata;
                request_we <= cpu_we;
                request_tag <= decoded_tag;
                request_index <= decoded_index;
                request_word_offset <= decoded_word_offset;
                request_line_address <= decoded_line_address;
                miss_already_counted <= 1'b0;
            end

            if (state == LOOKUP && !cache_hit)
                miss_already_counted <= 1'b1;
        end
    end

    always @(*) begin
        cpu_ready = 1'b0;
        cpu_rdata = 32'd0;

        mem_req = 1'b0;
        mem_we = 1'b0;
        mem_addr = 32'd0;
        mem_wdata = cache_line;

        tag_index = request_index;
        tag_write_enable = 1'b0;
        tag_write_data = request_tag;
        tag_valid_in = 1'b1;
        tag_dirty_in = 1'b0;

        data_index = request_index;
        data_word_offset = request_word_offset;
        word_write_enable = 1'b0;
        word_write_data = request_wdata;
        line_write_enable = 1'b0;
        line_write_data = mem_rdata;

        hit_pulse = 1'b0;
        miss_pulse = 1'b0;
        state_debug = state;

        case (state)
            IDLE: begin
            end

            LOOKUP: begin
                if (cache_hit) begin
                    if (!miss_already_counted)
                        hit_pulse = 1'b1;
                    cpu_ready = 1'b1;

                    if (request_we) begin
                        word_write_enable = 1'b1;
                        tag_write_enable = 1'b1;
                        tag_write_data = request_tag;
                        tag_valid_in = 1'b1;
                        tag_dirty_in = 1'b1;
                    end else begin
                        cpu_rdata = cache_word;
                    end
                end else begin
                    if (!miss_already_counted)
                        miss_pulse = 1'b1;
                end
            end

            WB_REQ, WB_WAIT: begin
                mem_req = 1'b1;
                mem_we = 1'b1;
                mem_addr = {stored_tag, request_index, 4'b0000};
                mem_wdata = cache_line;
            end

            WB_GAP: begin
            end

            REFILL_REQ, REFILL_WAIT: begin
                mem_req = 1'b1;
                mem_we = 1'b0;
                mem_addr = request_line_address;

                if (state == REFILL_WAIT && mem_ready) begin
                    line_write_enable = 1'b1;
                    line_write_data = mem_rdata;
                    tag_write_enable = 1'b1;
                    tag_write_data = request_tag;
                    tag_valid_in = 1'b1;
                    tag_dirty_in = 1'b0;
                end
            end

            REPLAY: begin
            end

            default: begin
            end
        endcase
    end
endmodule
