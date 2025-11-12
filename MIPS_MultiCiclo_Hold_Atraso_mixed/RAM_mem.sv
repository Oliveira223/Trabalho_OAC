// SystemVerilog replacement of the VHDL RAM_mem behavioral model
// Interface matches the VHDL entity used by the CPU_tb testbench

module RAM_mem #(
    parameter logic [31:0] START_ADDRESS = 32'h00000000,
    parameter int MEMORY_SIZE = 2048
)(
    input  logic ce_n,
    input  logic we_n,
    input  logic oe_n,
    input  logic bw, // byte-write indicator (not fully modeled here)
    input  logic [31:0] address,
    inout  logic [31:0] data
);

    // internal memory as bytes (little-endian)
    logic [7:0] ram [0:MEMORY_SIZE];
    logic [31:0] data_out;
    logic drive_data;
    logic [31:0] tmp_address;
    logic valid_addr;

    // compute offset
    always_comb begin
        tmp_address = address - START_ADDRESS;
        if ($signed(tmp_address[31:0]) >= 0 && tmp_address[15:0] <= (MEMORY_SIZE-3)) begin
            valid_addr = 1'b1;
        end else begin
            valid_addr = 1'b0;
        end
    end

    // write (asynchronous in VHDL model)
    always_ff @(ce_n, we_n, tmp_address, data) begin
        if (ce_n == 1'b0 && we_n == 1'b0 && valid_addr) begin
            // little endian: highest byte at address+3
            ram[$unsigned(tmp_address)+3] <= data[31:24];
            ram[$unsigned(tmp_address)+2] <= data[23:16];
            ram[$unsigned(tmp_address)+1] <= data[15:8];
            ram[$unsigned(tmp_address)+0] <= data[7:0];
        end
    end

    // read
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

    // tri-state data bus
    assign data = drive_data ? data_out : 32'bz;

endmodule
