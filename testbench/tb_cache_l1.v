`timescale 1ns/1ps

// Testbench para cache_l1
// - inclui um modelo simples de memória (leitura combinacional, escrita no posedge clk)
// - faz uma leitura que acarreta miss (preenche bloco) e depois uma leitura que deve ser hit

module tb_cache_l1;
    reg clk;
    reg rst;

    // CPU signals
    reg        cpu_ce;
    reg        cpu_rw; // 1=read, 0=write
    reg [31:0] cpu_addr;
    wire [31:0] cpu_data; // inout from cache
    reg [31:0] cpu_data_drive; // when CPU writes, drives this
    reg        cpu_drive_enable; // CPU drives cpu_data when writing
    // Tie cpu_data to CPU drive only when CPU intends to write
    assign cpu_data = cpu_drive_enable ? cpu_data_drive : 32'bz;

    wire cpu_hold;
    wire last_access_hit;

    // Memory side wires
    wire mem_ce;
    wire mem_rw;
    wire [31:0] mem_addr;
    wire [31:0] mem_data; // inout between cache and mem model

    // Instantiate cache (from src)
    cache_l1 uut (
        .clk(clk),
        .rst(rst),
        .cpu_ce(cpu_ce),
        .cpu_rw(cpu_rw),
        .cpu_addr(cpu_addr),
        .cpu_data(cpu_data),
        .cpu_hold(cpu_hold),
        .mem_ce(mem_ce),
        .mem_rw(mem_rw),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .last_access_hit(last_access_hit)
    );

    // Simple memory model
    // - asynchronous read (combinational): mem_data driven when mem_ce && mem_rw
    // - synchronous write (on posedge clk) when mem_ce && !mem_rw
    reg [31:0] mem_array [0:255];
    // combinational read data
    wire [31:0] mem_read_data;
    assign mem_read_data = mem_array[mem_addr[9:2]];
    // memory drives the bidir bus only on read cycles
    assign mem_data = (mem_ce && mem_rw) ? mem_read_data : 32'bz;

    // perform writes on clock edge
    always @(posedge clk) begin
        if (mem_ce && !mem_rw) begin
            mem_array[mem_addr[9:2]] <= mem_data; // sample bus driven by cache
        end
    end

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz -> 10 ns period (for example)
    end

    // Initialize memory with a known pattern
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem_array[i] = 32'h1000_0000 + i; // arbitrary pattern
        end
    end

    // Test sequence
    initial begin
        // dump
        $dumpfile("tb_cache_l1.vcd");
        $dumpvars(0, tb_cache_l1);

        // reset
        rst = 1;
        cpu_ce = 0;
        cpu_rw = 1;
        cpu_addr = 32'b0;
        cpu_drive_enable = 0;
        cpu_data_drive = 32'b0;
        #20;
        rst = 0;
        #20;

        // --- Test 1: Read from address that will miss (cache empty) ---
        // Choose an address (word-aligned). Example: address = 0x00000020
        cpu_addr = 32'h00000020; // maps to line index (depends on parameters)
        cpu_rw = 1; // read
        cpu_ce = 1; // request

        // keep cpu_ce asserted while cpu_hold is asserted
        wait (cpu_hold == 1);
        $display("[TB] Miss started at time %0t, cpu_hold=%0d", $time, cpu_hold);

        // wait until cache finishes filling
        wait (cpu_hold == 0);
        // allow one cycle for cpu_data to be driven
        @(posedge clk);
        $display("[TB] After fill at time %0t: cpu_data=%08h last_access_hit=%0d", $time, cpu_data, last_access_hit);

        cpu_ce = 0; // release
        #10;

        // --- Test 2: Read same address again: should be a hit ---
        cpu_addr = 32'h00000020;
        cpu_rw = 1;
        cpu_ce = 1;
        @(posedge clk);
        $display("[TB] Second read at time %0t: cpu_data=%08h last_access_hit=%0d", $time, cpu_data, last_access_hit);
        cpu_ce = 0;

        #50;
        $display("[TB] Test finished");
        $finish;
    end

endmodule
