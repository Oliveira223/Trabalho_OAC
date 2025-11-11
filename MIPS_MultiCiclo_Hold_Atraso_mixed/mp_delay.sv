// Simple MP delay module (not directly instantiated by the original TB)
// Provides an interface similar to RAM_mem but with an optional latency.

module mp_delay #(
    parameter int LATENCY = 16,
    parameter int MEMORY_SIZE = 2048,
    parameter logic [31:0] START_ADDRESS = 32'h00000000
)(
    input  logic ce_n,
    input  logic we_n,
    input  logic oe_n,
    input  logic bw,
    input  logic [31:0] address,
    inout  logic [31:0] data
);

    // Underlying storage
    logic [7:0] ram [0:MEMORY_SIZE];
    logic [31:0] data_out;
    logic drive_data;
    logic [31:0] tmp_address;
    logic valid_addr;

    // Simple latency model: not wired into TB by default. This module is
    // provided for future connection with l1_cache; it currently behaves
    // like RAM_mem (zero-effective delay) but keeps parameter LATENCY.

    always_comb begin
        tmp_address = address - START_ADDRESS;
        if ($signed(tmp_address[31:0]) >= 0 && tmp_address[15:0] <= (MEMORY_SIZE-3)) begin
            valid_addr = 1'b1;
        end else begin
            valid_addr = 1'b0;
        end
    end

    always_ff @(ce_n, we_n, tmp_address, data) begin
        if (ce_n == 1'b0 && we_n == 1'b0 && valid_addr) begin
            ram[$unsigned(tmp_address)+3] <= data[31:24];
            ram[$unsigned(tmp_address)+2] <= data[23:16];
            ram[$unsigned(tmp_address)+1] <= data[15:8];
            ram[$unsigned(tmp_address)+0] <= data[7:0];
        end
    end

    always_comb begin
        if (ce_n == 1'b0 && oe_n == 1'b0 && valid_addr) begin
            data_out[31:24] = ram[$unsigned(tmp_address)+3];
            data_out[23:16] = ram[$unsigned(tmp_address)+2];
            data_out[15:8]  = ram[$unsigned(tmp_address)+1];
            data_out[7:0]   = ram[$unsigned(tmp_address)+0];
            drive_data = 1'b1;
        end else begin
            data_out = 32'bz;
            drive_data = 1'b0;
        end
    end

    assign data = drive_data ? data_out : 32'bz;

endmodule
