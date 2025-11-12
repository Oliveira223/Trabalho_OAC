//8 lines
//block size = 8 words (32 bytes)
//write-through, no write-allocate
//single-cycle hit

module cache_l1(
    input  wire        clk,
    input  wire        rst,

    // CPU side
    input  wire        cpu_ce,    // chip enable (active high)
    input  wire        cpu_rw,    // 1 = read, 0 = write
    input  wire [31:0] cpu_addr,
    inout  wire [31:0] cpu_data,
    output reg         cpu_hold,  // assert to pause CPU while servicing a miss

    // Memory side
    output reg         mem_ce,
    output reg         mem_rw,    // 1 = read, 0 = write
    output reg  [31:0] mem_addr,
    inout  wire [31:0] mem_data,

    // debug
    output reg         last_access_hit
);

// ==================================================================
// Parametros Fixos
// ===================================================================
localparam LINES = 8;                 // Num de linhas
localparam WORDS_PER_BLOCK = 8;       // Palavra por bloco (word = 32 bits)

localparam INDEX_BITS = 3;            
localparam BLOCK_OFFSET_BITS = 5;     
localparam WORD_INDEX_BITS = 3;       // Qual palavra dentro do bloco (BITS [4:2])
localparam TAG_BITS = 32 - INDEX_BITS - BLOCK_OFFSET_BITS; // rest of address bits

// ==================================================================
// Aqui fica a Cache de fato.
// ==================================================================
reg [31:0] cache_data [0:(LINES*WORDS_PER_BLOCK)-1];
reg [TAG_BITS-1:0] tags [0:LINES-1];
reg valid [0:LINES-1];

// =================================================================
// Define como o endereçeo da CPU é particionado
//
// block_off : 5 menos significativos -> Offset dentro do bloco
// index     : 3 menos significativos -> Qual linha da cache (INDEX_BITS bits)
// cpu_tag   : bits resstantes        -> Usados como tag
// word_index: Qual palavra dentro do bloco (WORD_INDEX_BITS bits)
//
// =================================================================

wire [BLOCK_OFFSET_BITS-1:0] block_off;
wire [INDEX_BITS-1:0] index;
wire [TAG_BITS-1:0] cpu_tag;
wire [WORD_INDEX_BITS-1:0] word_index;

assign block_off  = cpu_addr[BLOCK_OFFSET_BITS-1:0];
assign index      = cpu_addr[BLOCK_OFFSET_BITS + INDEX_BITS - 1 : BLOCK_OFFSET_BITS];
assign cpu_tag    = cpu_addr[31 : BLOCK_OFFSET_BITS + INDEX_BITS];
assign word_index = block_off[BLOCK_OFFSET_BITS-1:2];


// =====================================================================
// Tráfego de dados CPU <-> Cache e Memória <-> Cache
// =====================================================================
// CPU read data and driver enable (names chosen to be explicit)
reg [31:0] cpu_rdata_out;   // dados que a cache entrega à CPU em leitura
reg        cpu_drive;        // 1 = cache dirige cpu_data; 0 = CPU dirige (em escrita)

// Quando cpu_drive = 1, a cache coloca cpu_rdata_out em cpu_data.
// Quando cpu_drive = 0, cpu_data fica em Z para que a CPU dirija.
assign cpu_data = cpu_drive ? cpu_rdata_out : 32'bz; // z = high-impedance

// Memory write data and driver enable (names explícitos)
reg [31:0] mem_wdata_out;   // dados que a cache envia para memória em write
reg        mem_drive;        // 1 = cache dirige mem_data (escrita); 0 = memória dirige (leitura)

// Quando mem_drive = 1, a cache coloca mem_wdata_out em mem_data.
// Quando mem_drive = 0, mem_data fica em Z para que a memória dirija.
assign mem_data = mem_drive ? mem_wdata_out : 32'bz;

// ------------------------------------------------------------------
// Pequena FSM para cuidar de misses
// S_IDLE     : operação normal (solicitação de serviço da CPU)
// S_READMISS : estamos buscando o bloco inteiro da memória, palabra por palavra
// ------------------------------------------------------------------
localparam S_IDLE = 0;
localparam S_READMISS = 1;

reg [1:0] state;
reg [WORD_INDEX_BITS-1:0] read_word_counter; // contador 0 .. PALAVRA-POR-BLOCO-1
reg [TAG_BITS-1:0] miss_tag;
reg [31:0] miss_block_base; // endereço alinhado com o bloco base (endereço de byte)

// ------------------------------------------------------------------
// Reset e sequência lógica principal
// ------------------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // limpa dado e metadado
        for (i = 0; i < LINES*WORDS_PER_BLOCK; i = i + 1) begin
            cache_data[i] <= 32'h0;
        end
        for (i = 0; i < LINES; i = i + 1) begin
            valid[i] <= 1'b0;
            tags[i] <= {TAG_BITS{1'b0}};
        end

        // saida default 
        mem_ce <= 1'b0;
        mem_rw <= 1'b1;
        mem_addr <= 32'b0;
        cpu_hold <= 1'b0;
        cpu_drive <= 1'b0;
        mem_drive <= 1'b0;
        last_access_hit <= 1'b0;

        // FSM
        state <= S_IDLE;
        read_word_counter <= {WORD_INDEX_BITS{1'b0}};
    end else begin
        // default: do not drive cpu or mem unless we need to this cycle
    cpu_drive <= 1'b0;
    mem_drive <= 1'b0;
        mem_ce <= 1'b0;

        case (state)
            S_IDLE: begin
                cpu_hold <= 1'b0; //normalmente deixa a CPU rodar
                if (cpu_ce) begin
                    if (cpu_rw == 1'b1) begin
                        // CPU quer ler
                        if (valid[index] && (tags[index] == cpu_tag)) begin
                            // HIT: give CPU the word from cache immediately
                            // compute base index for the line (index * words_per_block)
                            // use an integer local to keep expression readable
                            integer base_index;
                            base_index = index * WORDS_PER_BLOCK;
                            cpu_rdata_out <= cache_data[ base_index + word_index ];
                            cpu_drive <= 1'b1;
                            last_access_hit <= 1'b1;
                        end else begin
                            // MISS: start reading block from memory, hold CPU
                            last_access_hit <= 1'b0;
                            state <= S_READMISS;
                            read_word_counter <= 0;
                            miss_tag <= cpu_tag;
                            // align base address to block boundary (clear low BLOCK_OFFSET_BITS bits)
                            miss_block_base <= { cpu_addr[31 : BLOCK_OFFSET_BITS], {BLOCK_OFFSET_BITS{1'b0}} };
                            cpu_hold <= 1'b1; // tell CPU to wait while we fill the block
                        end
                    end else begin
                        // CPU wants to WRITE (write-through, no write-allocate)
                        integer base_index_w;
                        base_index_w = index * WORDS_PER_BLOCK;
                        if (valid[index] && (tags[index] == cpu_tag)) begin
                            // HIT on write: update cache word too (write-through)
                            cache_data[ base_index_w + word_index ] <= cpu_data; // assume cpu drives cpu_data
                            last_access_hit <= 1'b1;
                        end else begin
                            last_access_hit <= 1'b0;
                        end

                        // In all cases, perform a write to memory (write-through)
                        mem_ce <= 1'b1;
                        mem_rw <= 1'b0; // write
                        mem_addr <= cpu_addr;
                        mem_wdata_out <= cpu_data;
                        mem_drive <= 1'b1; // drive data to memory this cycle
                    end
                end
            end

            S_READMISS: begin
                // Request one word from memory each cycle
                mem_ce <= 1'b1;
                mem_rw <= 1'b1; // read
                mem_addr <= miss_block_base + (read_word_counter * 4); // word address

                // Capture memory's data into the correct location in cache
                // compute base index for this line and store at offset read_word_counter
                integer base_index_r;
                base_index_r = index * WORDS_PER_BLOCK;
                cache_data[ base_index_r + read_word_counter ] <= mem_data;

                // If this was the last word of the block, finish miss handling
                if (read_word_counter == (WORDS_PER_BLOCK - 1)) begin
                    valid[index] <= 1'b1;
                    tags[index] <= miss_tag;

                    // Now that the block is filled, drive the CPU with the requested word
                    cpu_rdata_out <= cache_data[ base_index_r + word_index ];
                    cpu_drive <= 1'b1;
                    cpu_hold <= 1'b0;
                    state <= S_IDLE;
                end else begin
                    // Not finished: increment counter and remain in read-miss
                    read_word_counter <= read_word_counter + 1;
                    cpu_hold <= 1'b1;
                end
            end

            default: begin
                state <= S_IDLE;
            end
        endcase
    end
end

endmodule
