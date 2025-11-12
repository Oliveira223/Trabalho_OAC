// Memory with configurable latency and ack signal for L1 cache integration
// This module adds a clock-based latency counter and ack output

module mp_delay_with_ack #(
    parameter int LATENCY = 16,
    parameter int MEMORY_SIZE = 2048,
    parameter logic [31:0] START_ADDRESS = 32'h00000000
)(
    input  logic clk,
    input  logic reset_n,
    input  logic ce_n,
    input  logic we_n,
    input  logic oe_n,
    input  logic bw,
    input  logic [31:0] address,
    inout  logic [31:0] data,
    output logic ack
);

    // Underlying storage (reusing RAM_mem storage)
    logic [7:0] ram [0:MEMORY_SIZE];
    logic [31:0] data_out;
    logic drive_data;
    logic [31:0] tmp_address;
    logic valid_addr;
    
    // Latency counter
    logic [7:0] latency_counter;
    logic request_pending;
    logic [31:0] pending_addr;
    logic pending_write;
    logic [31:0] write_data;
    
    // Address calculation
    always_comb begin
        tmp_address = address - START_ADDRESS;
        if ($signed(tmp_address[31:0]) >= 0 && tmp_address[15:0] <= (MEMORY_SIZE-3)) begin
            valid_addr = 1'b1;
        end else begin
            valid_addr = 1'b0;
        end
    end
    
    // Latency FSM
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            latency_counter <= 0;
            request_pending <= 1'b0;
            ack <= 1'b0;
            pending_write <= 1'b0;
            drive_data <= 1'b0;
            data_out <= 32'bz;
        end else begin
            // Default: no ack
            ack <= 1'b0;
            
            // New request
            if (ce_n == 1'b0 && !request_pending && valid_addr) begin
                request_pending <= 1'b1;
                latency_counter <= LATENCY - 1;
                pending_addr <= tmp_address;
                
                if (we_n == 1'b0) begin
                    // Write request
                    pending_write <= 1'b1;
                    write_data <= data;
                end else begin
                    // Read request
                    pending_write <= 1'b0;
                end
            end
            // Count down latency
            else if (request_pending) begin
                if (latency_counter == 0) begin
                    // Latency complete - perform operation
                    ack <= 1'b1;
                    request_pending <= 1'b0;
                    
                    if (pending_write) begin
                        // Execute write
                        ram[$unsigned(pending_addr)+3] <= write_data[31:24];
                        ram[$unsigned(pending_addr)+2] <= write_data[23:16];
                        ram[$unsigned(pending_addr)+1] <= write_data[15:8];
                        ram[$unsigned(pending_addr)+0] <= write_data[7:0];
                        drive_data <= 1'b0;
                    end else begin
                        // Execute read
                        data_out[31:24] <= ram[$unsigned(pending_addr)+3];
                        data_out[23:16] <= ram[$unsigned(pending_addr)+2];
                        data_out[15:8]  <= ram[$unsigned(pending_addr)+1];
                        data_out[7:0]   <= ram[$unsigned(pending_addr)+0];
                        drive_data <= 1'b1;
                    end
                end else begin
                    latency_counter <= latency_counter - 1;
                end
            end else begin
                drive_data <= 1'b0;
            end
        end
    end
    
    // Data bus driver
    assign data = drive_data ? data_out : 32'bz;

endmodule
