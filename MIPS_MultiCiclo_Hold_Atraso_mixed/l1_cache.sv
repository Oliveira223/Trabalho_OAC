// Simple SystemVerilog L1 cache skeleton (direct-mapped, 8 lines x 8 words)
// Not yet wired into the testbench automatically. Use this module when
// you want to replace the RAM_mem instantiation with the cache topology.

module l1_cache(
    input  logic         clk,
    input  logic         reset_n,

    // CPU side
    input  logic [31:0]  cpu_addr,
    inout  logic [31:0]  cpu_data,
    input  logic         cpu_ce,
    input  logic         cpu_rw,
    input  logic         cpu_bw,
    output logic         cpu_ack,
    output logic         cpu_hit,

    // MEM side
    output logic [31:0]  mem_addr,
    inout  logic [31:0]  mem_data,
    output logic         mem_ce,
    output logic         mem_rw,
    input  logic         mem_ack
);

    localparam LINES = 8;
    localparam WORDS_PER_LINE = 8;

    // storage: [line][word]
    logic [31:0] cache_data [0:LINES-1][0:WORDS_PER_LINE-1];
    logic [23:0] cache_tag  [0:LINES-1];
    logic        cache_valid[0:LINES-1];

    logic [2:0]  index;
    logic [4:0]  offset;
    logic [23:0] tag;
    logic [31:0] read_data;
    logic        hit;
    integer      i;

    // Burst/fill state
    typedef enum logic [1:0] {S_IDLE, S_FILL, S_WRITE} state_t;
    state_t state, next_state;

    logic [2:0] fill_idx; // which word of the line we're fetching
    logic [2:0] target_word; // requested word index inside block
    logic [31:0] block_base_addr;
    logic fill_first_word_seen;

    // Write handling
    logic write_pending;
    logic [31:0] write_data_reg;

    // mem data driver
    logic mem_drive;
    logic [31:0] mem_data_out;
    assign mem_data = mem_drive ? mem_data_out : 32'bz;

    // cpu data driver (drive only on read ack)
    logic cpu_drive;
    assign cpu_data = cpu_drive ? read_data : 32'bz;

    assign offset = cpu_addr[4:0];
    assign index  = cpu_addr[7:5];
    assign tag    = cpu_addr[31:8];

    assign cpu_hit = hit;

    // Helper: align address to block base (zero low 5 bits)
    always_comb begin
        block_base_addr = {cpu_addr[31:5], 5'b0};
    end

    // synchronous FSM and datapath
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < LINES; i=i+1) begin
                cache_valid[i] <= 1'b0;
                cache_tag[i] <= 24'b0;
                for (int j=0; j<WORDS_PER_LINE; j=j+1) cache_data[i][j] <= 32'b0;
            end
            cpu_ack <= 1'b0;
            hit <= 1'b0;
            state <= S_IDLE;
            fill_idx <= 3'b0;
            target_word <= 3'b0;
            fill_first_word_seen <= 1'b0;
            write_pending <= 1'b0;
            mem_drive <= 1'b0;
            mem_data_out <= 32'b0;
            mem_ce <= 1'b0;
            mem_rw <= 1'b1;
            mem_addr <= 32'b0;
            read_data <= 32'b0;
        end else begin
            // default outputs
            cpu_ack <= 1'b0;
            cpu_drive <= 1'b0;
            case (state)
                S_IDLE: begin
                    mem_ce <= 1'b0;
                    mem_drive <= 1'b0;
                    mem_data_out <= 32'b0;
                    // normal CPU request
                    if (cpu_ce) begin
                        if (cache_valid[index] && cache_tag[index] == tag) begin
                            // HIT
                            hit <= 1'b1;
                            read_data <= cache_data[index][ offset[4:2] ];
                            cpu_ack <= 1'b1;
                            cpu_drive <= 1'b1;
                            // For writes, update cache and start write-through
                            if (!cpu_rw) begin
                                // capture write data
                                write_data_reg <= cpu_data;
                                cache_data[index][ offset[4:2] ] <= cpu_data;
                                // start mem write
                                mem_ce <= 1'b1;
                                mem_rw <= 1'b0; // write
                                mem_addr <= cpu_addr;
                                mem_data_out <= cpu_data;
                                mem_drive <= 1'b1;
                                state <= S_WRITE;
                                write_pending <= 1'b1;
                            end
                        end else begin
                            // MISS -> start fill
                            hit <= 1'b0;
                            target_word <= offset[4:2];
                            fill_idx <= 3'b0;
                            fill_first_word_seen <= 1'b0;
                            // capture write data if this is a write (write-allocate)
                            if (!cpu_rw) begin
                                write_data_reg <= cpu_data;
                                write_pending <= 1'b1;
                            end else begin
                                write_pending <= 1'b0;
                            end
                            // start requesting from mem the block words sequentially
                            mem_ce <= 1'b1;
                            mem_rw <= 1'b1; // read
                            mem_addr <= block_base_addr + ({{29{1'b0}}, fill_idx} << 2);
                            state <= S_FILL;
                        end
                    end
                end

                S_FILL: begin
                    // keep mem_ce asserted while fetching
                    mem_ce <= 1'b1;
                    mem_rw <= 1'b1;
                    mem_addr <= block_base_addr + ({{29{1'b0}}, fill_idx} << 2);
                    // when mem provides data
                    if (mem_ack) begin
                        // store fetched word
                        cache_data[index][fill_idx] <= mem_data;
                        // when the fetched word is the one CPU requested, respond to CPU
                        if (fill_idx == target_word && !fill_first_word_seen) begin
                            if (write_pending) begin
                                // write-allocate: perform the CPU write into cache at the target word
                                cache_data[index][fill_idx] <= write_data_reg;
                                read_data <= write_data_reg;
                                cpu_ack <= 1'b1;
                                cpu_drive <= 1'b0; // not driving for write ack
                            end else begin
                                read_data <= mem_data;
                                cpu_ack <= 1'b1;
                                cpu_drive <= 1'b1;
                            end
                            fill_first_word_seen <= 1'b1;
                        end
                        // move to next word or finish
                        if (fill_idx == WORDS_PER_LINE-1) begin
                            // finish fill: update tag/valid
                            cache_tag[index] <= tag;
                            cache_valid[index] <= 1'b1;
                            mem_ce <= 1'b0;
                            state <= S_IDLE;
                            // if write_pending, need to perform write-through for the written word
                            if (write_pending) begin
                                // issue write to memory for target word (write-through)
                                mem_ce <= 1'b1;
                                mem_rw <= 1'b0;
                                mem_addr <= block_base_addr + ({{29{1'b0}}, target_word} << 2);
                                mem_data_out <= cache_data[index][target_word];
                                mem_drive <= 1'b1;
                                state <= S_WRITE;
                            end
                        end else begin
                            fill_idx <= fill_idx + 1;
                            // prepare next mem_addr; mem_ce remains asserted until last
                            mem_addr <= block_base_addr + ({{29{1'b0}}, (fill_idx+1)} << 2);
                        end
                    end
                end

                S_WRITE: begin
                    // wait for mem ack of write
                    mem_ce <= 1'b1;
                    mem_rw <= 1'b0;
                    // mem_addr and mem_data_out already set by whoever started write
                    if (mem_ack) begin
                        // done with write
                        mem_ce <= 1'b0;
                        mem_drive <= 1'b0;
                        mem_data_out <= 32'b0;
                        write_pending <= 1'b0;
                        cpu_ack <= 1'b1; // ack CPU write (if it hasn't been acked earlier)
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
