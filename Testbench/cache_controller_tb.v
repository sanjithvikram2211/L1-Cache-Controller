`timescale 1ns/1ps

module cache_controller_tb;
    reg clk, reset;
    reg cpu_req, cpu_we;
    reg [31:0] cpu_addr, cpu_wdata;
    wire cpu_ready;
    wire [31:0] cpu_rdata;

    wire mem_req, mem_we;
    wire [31:0] mem_addr;
    wire [127:0] mem_wdata, mem_rdata;
    wire mem_ready;

    wire [31:0] hit_count, miss_count;
    wire [3:0] state_debug;
    integer errors;

    cache_top dut (
        .clk(clk), .reset(reset),
        .cpu_req(cpu_req), .cpu_we(cpu_we),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_ready(cpu_ready), .cpu_rdata(cpu_rdata),
        .mem_req(mem_req), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata),
        .hit_count(hit_count), .miss_count(miss_count),
        .state_debug(state_debug)
    );

    simple_memory memory_model (
        .clk(clk), .reset(reset),
        .mem_req(mem_req), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata)
    );

    always #5 clk = ~clk;

    // One request is held high until cpu_ready. It is then lowered for a
    // clock interval before the next request, matching the CPU handshake.
    task cpu_access;
        input write_enable;
        input [31:0] address;
        input [31:0] write_data;
        input [31:0] expected_read_data;
        input check_read;
        integer wait_cycles;
        begin
            @(negedge clk);
            cpu_req = 1'b1;
            cpu_we = write_enable;
            cpu_addr = address;
            cpu_wdata = write_data;

            wait_cycles = 0;
            while ((cpu_ready !== 1'b1) && (wait_cycles < 100)) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (cpu_ready !== 1'b1) begin
                $display("ERROR: TIMEOUT addr=%h", address);
                errors = errors + 1;
            end else if (check_read) begin
                if (cpu_rdata === expected_read_data)
                    $display("READ PASS  addr=%h data=%h", address, cpu_rdata);
                else begin
                    $display("READ FAIL  addr=%h expected=%h actual=%h",
                             address, expected_read_data, cpu_rdata);
                    errors = errors + 1;
                end
            end else begin
                $display("WRITE DONE addr=%h data=%h", address, write_data);
            end

            @(negedge clk);
            cpu_req = 1'b0;
            cpu_we = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cpu_req = 1'b0;
        cpu_we = 1'b0;
        cpu_addr = 32'd0;
        cpu_wdata = 32'd0;
        errors = 0;

        $display("================================================");
        $display("       MODULAR L1 CACHE CONTROLLER TEST");
        $display("================================================");

        repeat (3) @(negedge clk);
        reset = 1'b0;
        repeat (1) @(negedge clk);

        if (hit_count !== 0 || miss_count !== 0 ||
            dut.tag_array.valid[0] !== 1'b0 ||
            dut.tag_array.valid[1] !== 1'b0 ||
            dut.tag_array.valid[2] !== 1'b0 ||
            dut.tag_array.valid[3] !== 1'b0) begin
            $display("RESET CHECK FAIL");
            errors = errors + 1;
        end else begin
            $display("RESET CHECK PASS");
        end

        // Cold write miss, allocate line, then read hit.
        cpu_access(1'b1, 32'h00000000, 32'h12345678, 32'd0, 1'b0);
        cpu_access(1'b0, 32'h00000000, 32'd0, 32'h12345678, 1'b1);

        // 0x00 and 0x40 share index 0: dirty eviction/writeback.
        cpu_access(1'b1, 32'h00000040, 32'hCAFEBABE, 32'd0, 1'b0);

        // Reload 0x00; this forces writeback of dirty 0x40 line too.
        cpu_access(1'b0, 32'h00000000, 32'd0, 32'h12345678, 1'b1);
        cpu_access(1'b0, 32'h00000040, 32'd0, 32'hCAFEBABE, 1'b1);

        // Index 1: another cold write miss followed by a read hit.
        cpu_access(1'b1, 32'h00000010, 32'h0BADF00D, 32'd0, 1'b0);
        cpu_access(1'b0, 32'h00000010, 32'd0, 32'h0BADF00D, 1'b1);

        repeat (3) @(negedge clk);

        // Directly verify that both dirty evictions reached main memory.
        if (memory_model.memory[0][31:0] === 32'h12345678)
            $display("WRITEBACK PASS addr=00000000 data=12345678");
        else begin
            $display("WRITEBACK FAIL addr=00000000 actual=%h",
                     memory_model.memory[0][31:0]);
            errors = errors + 1;
        end

        if (memory_model.memory[4][31:0] === 32'hCAFEBABE)
            $display("WRITEBACK PASS addr=00000040 data=CAFEBABE");
        else begin
            $display("WRITEBACK FAIL addr=00000040 actual=%h",
                     memory_model.memory[4][31:0]);
            errors = errors + 1;
        end

        if (hit_count === 32'd2 && miss_count === 32'd5)
            $display("HIT/MISS COUNT PASS hits=%0d misses=%0d", hit_count, miss_count);
        else begin
            $display("HIT/MISS COUNT FAIL hits=%0d misses=%0d", hit_count, miss_count);
            errors = errors + 1;
        end

        $display("------------------------------------------------");
        $display("FINAL HIT COUNT  = %0d", hit_count);
        $display("FINAL MISS COUNT = %0d", miss_count);
        $display("TOTAL ERRORS     = %0d", errors);
        if (errors == 0)
            $display("===== ALL TESTS PASSED =====");
        else
            $display("===== TESTS FAILED =====");
        $display("================================================");
        $finish;
    end
endmodule
