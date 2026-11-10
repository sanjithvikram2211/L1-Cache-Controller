module cache_top (
    input wire clk, reset,
    input wire cpu_req, cpu_we,
    input wire [31:0] cpu_addr, cpu_wdata,
    output wire cpu_ready,
    output wire [31:0] cpu_rdata,

    output wire mem_req, mem_we,
    output wire [31:0] mem_addr,
    output wire [127:0] mem_wdata,
    input wire mem_ready,
    input wire [127:0] mem_rdata,

    output wire [31:0] hit_count, miss_count,
    output wire [3:0] state_debug
);
    wire [25:0] decoded_tag, stored_tag;
    wire [1:0] decoded_index, decoded_word_offset;
    wire [31:0] decoded_line_address;
    wire stored_valid, stored_dirty;

    wire [1:0] tag_index, data_index, data_word_offset;
    wire tag_write_enable, tag_valid_in, tag_dirty_in;
    wire [25:0] tag_write_data;

    wire [31:0] cache_word, word_write_data;
    wire [127:0] cache_line, line_write_data;
    wire word_write_enable, line_write_enable;
    wire hit_pulse, miss_pulse;

    cache_address_decoder decoder (
        .address(cpu_addr),
        .tag(decoded_tag),
        .index(decoded_index),
        .word_offset(decoded_word_offset),
        .line_address(decoded_line_address)
    );

    cache_tag_array tag_array (
        .clk(clk), .reset(reset), .index(tag_index),
        .tag_out(stored_tag), .valid_out(stored_valid), .dirty_out(stored_dirty),
        .write_enable(tag_write_enable), .tag_in(tag_write_data),
        .valid_in(tag_valid_in), .dirty_in(tag_dirty_in)
    );

    cache_data_array data_array (
        .clk(clk), .reset(reset),
        .index(data_index), .word_offset(data_word_offset),
        .word_out(cache_word), .line_out(cache_line),
        .word_write_enable(word_write_enable), .word_in(word_write_data),
        .line_write_enable(line_write_enable), .line_in(line_write_data)
    );

    cache_controller controller (
        .clk(clk), .reset(reset),
        .cpu_req(cpu_req), .cpu_we(cpu_we),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_ready(cpu_ready), .cpu_rdata(cpu_rdata),
        .mem_req(mem_req), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata),
        .tag_index(tag_index), .stored_tag(stored_tag),
        .stored_valid(stored_valid), .stored_dirty(stored_dirty),
        .tag_write_enable(tag_write_enable), .tag_write_data(tag_write_data),
        .tag_valid_in(tag_valid_in), .tag_dirty_in(tag_dirty_in),
        .data_index(data_index), .data_word_offset(data_word_offset),
        .cache_word(cache_word), .cache_line(cache_line),
        .word_write_enable(word_write_enable), .word_write_data(word_write_data),
        .line_write_enable(line_write_enable), .line_write_data(line_write_data),
        .decoded_tag(decoded_tag), .decoded_index(decoded_index),
        .decoded_word_offset(decoded_word_offset),
        .decoded_line_address(decoded_line_address),
        .hit_pulse(hit_pulse), .miss_pulse(miss_pulse),
        .state_debug(state_debug)
    );

    cache_counter counters (
        .clk(clk), .reset(reset),
        .hit_pulse(hit_pulse), .miss_pulse(miss_pulse),
        .hit_count(hit_count), .miss_count(miss_count)
    );
endmodule
