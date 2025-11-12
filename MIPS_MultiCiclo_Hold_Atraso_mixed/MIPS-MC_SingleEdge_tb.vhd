-------------------------------------------------------------------------
--
--  TESTBENCH DO PROCESSADOR MIPS_S (LITTLE ENDIAN) 13/10/2004
--
-- Observe-se que o processador come�a sendo ressetado por este testbench
-- (rstCPU <= '1') no in�cio da simula��o, sendo ativado  -- (rstCPU <= '0')
-- somente depois do fim da leitura do arquiv contendo o c�digo objeto do
-- programa e executar, bem como seus dados iniciais.
--
-- Este testbench emprega duas mem�rias, implicando uma organiza��o HARVARD
-- para o processador
--
-- Mudan�as:
--	16/05/2012 (Ney Calazans)
--		- Bug corrigido no processo de preenchimento da mem�ria durante o reset.
--		Anteriormente, o processo fazia o processador produzir habilita��es no 
--      sinal ce para a mem�ria o que acabava preenchendo a mem�ria de dados 
--      com lixo ao mesmo tempo. Para resolver isto, a gera��o do sinal de 
--      controle Dce da mem�ria de dados foi mudada de 
--		--	ce='1' or go_d='1'	 
--          para 
--		-- (ce='1' and rstCPU/='1') or go_d='1'
--		- Al�m disto, havia um problema com a opera��o de escrita da mem�ria de 
--      dados nas implementa��es monociclo do MIPS: quando m�ltiplas instru��es
--      SW eram programadas uma ap�s  outra, a escrita ocorria  em dois conjuntos
--		de posi��es da mem�ria ao mesmo tempo ap�s o primeiro SW da s�rie.
--      Para resolver isto o sinal data foi removido da lista de sensitividade 
--      do processo de escrita na mem�ria.
--	10/10/2015 (Ney Calazans)
--		- Sinal bw da mem�ria setado para '1', uma vez que a CPU
--		n�o gera mais ele.
--	28/10/2016 (Ney Calazans)
--		- Defini��es regX mudadas para wiresX, para melhora a readabilidade do
--		 c�digo.
--	02/06/2017 (Ney Calazans) - conserto de bugs
--		- tmp_address mudado para int_address na defini��o da mem�ria
--		- na defini��o dos processo de escrita/leitura da mem�ria
--		  CONV_INTEGER(low_address+3)<=MEMORY_SIZE 
--		foi mudado para
--		  CONV_INTEGER(low_address)<=MEMORY_SIZE-3
--		Isto evita um erro que congelava a simula��o quando a
--		   ALU continnha um n�mero grande (>65533) na sua sa�da 
--		imediatamente antes de uma instru��o LW o SW.
-------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use std.textio.all;
package aux_functions is  

	subtype wires32  is std_logic_vector(31 downto 0);
	subtype wires16  is std_logic_vector(15 downto 0);
	subtype wires8   is std_logic_vector( 7 downto 0);
	subtype wires4   is std_logic_vector( 3 downto 0);

   -- defini��o do tipo 'memory', que ser� utilizado para as mem�rias de dados/instru��es
   constant MEMORY_SIZE : integer := 2048;     
   type memory is array (0 to MEMORY_SIZE) of wires8;

   constant TAM_LINHA : integer := 200;
   
   function CONV_VECTOR( letra : string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector;
	
	procedure readFileLine(file in_file: TEXT; outStrLine: out string);
   
end aux_functions;

package body aux_functions is

  --
  -- converte um caracter de uma dada linha em um std_logic_vector
  --
  function CONV_VECTOR( letra:string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector is         
     variable bin: wires4;
   begin
      case (letra(pos)) is  
              when '0' => bin := "0000";
              when '1' => bin := "0001";
              when '2' => bin := "0010";
              when '3' => bin := "0011";
              when '4' => bin := "0100";
              when '5' => bin := "0101";
              when '6' => bin := "0110";
              when '7' => bin := "0111";
              when '8' => bin := "1000";
              when '9' => bin := "1001";
              when 'A' | 'a' => bin := "1010";
              when 'B' | 'b' => bin := "1011";
              when 'C' | 'c' => bin := "1100";
              when 'D' | 'd' => bin := "1101";
              when 'E' | 'e' => bin := "1110";
              when 'F' | 'f' => bin := "1111";
              when others =>  bin := "0000";  
      end case;
     return bin;
  end CONV_VECTOR;

  procedure readFileLine(file in_file: TEXT; 
				      outStrLine: out string) is
		
		variable localLine: line;
		variable localChar:  character;
		variable isString: 	boolean;
			
	begin
				
		 readline(in_file, localLine);

		 for i in outStrLine'range loop
			 outStrLine(i) := ' ';
		 end loop;   

		 for i in outStrLine'range loop
			read(localLine, localChar, isString);
			outStrLine(i) := localChar;
			if not isString then -- encontrou o fim da linha
				exit;
			end if;   
		 end loop; 
						 
	end readFileLine;
	
end aux_functions;     

--------------------------------------------------------------------------
-- NOTE: The VHDL architecture implementation of RAM_mem (behavioral RAM)
-- has been removed from this copy so a SystemVerilog implementation
-- (`RAM_mem.sv`) can provide the memory model in mixed-language Questa
-- simulations. The entity declaration remains and is provided below.
--------------------------------------------------------------------------
-- RAM_mem entity now provided by SystemVerilog module RAM_mem.sv
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Testebench para simular a CPU do processador
--------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          
use STD.TEXTIO.all;
use work.aux_functions.all;

entity CPU_tb is
end CPU_tb;

architecture cpu_tb of cpu_tb is
    
    -- Component declaration for SystemVerilog RAM_mem module
    component RAM_mem
        generic(START_ADDRESS: std_logic_vector(31 downto 0) := (others=>'0'));
        port(
            ce_n, we_n, oe_n, bw: in std_logic;
            address: in wires32;
            data: inout wires32
        );
    end component;
    
    -- Component declaration for L1 cache
    component l1_cache
        port(
            clk: in std_logic;
            reset_n: in std_logic;
            cpu_addr: in wires32;
            cpu_data: inout wires32;
            cpu_ce: in std_logic;
            cpu_rw: in std_logic;
            cpu_bw: in std_logic;
            cpu_ack: out std_logic;
            cpu_hit: out std_logic;
            mem_addr: out wires32;
            mem_data: inout wires32;
            mem_ce: out std_logic;
            mem_rw: out std_logic;
            mem_ack: in std_logic
        );
    end component;
    
    -- Component declaration for mp_delay with ack
    component mp_delay_with_ack
        generic(
            LATENCY: integer := 16;
            MEMORY_SIZE: integer := 2048;
            START_ADDRESS: std_logic_vector(31 downto 0) := (others=>'0')
        );
        port(
            clk: in std_logic;
            reset_n: in std_logic;
            ce_n, we_n, oe_n, bw: in std_logic;
            address: in wires32;
            data: inout wires32;
            ack: out std_logic
        );
    end component;
    
    signal Dadress, Ddata, Iadress, Idata,
           i_cpu_address, d_cpu_address, data_cpu, tb_add, tb_data : wires32 := (others => '0' );
    
    signal Dce_n, Dwe_n, Doe_n, Ice_n, Iwe_n, Ioe_n, ck, rst, rstCPU, hold,
           go_i, go_d, ce, rw, bw: std_logic;
	   
    signal readInst: std_logic;
    
    -- Sinais para cache L1 (memória de dados)
    signal cache_reset_n: std_logic;
    signal cache_cpu_addr: wires32;
    signal cache_cpu_data: wires32;
    signal cache_cpu_ce: std_logic;
    signal cache_cpu_rw: std_logic;
    signal cache_cpu_ack: std_logic;
    signal cache_cpu_hit: std_logic;
    signal cache_mem_addr: wires32;
    signal cache_mem_data: wires32;
    signal cache_mem_ce: std_logic;
    signal cache_mem_rw: std_logic;
    signal cache_mem_ack: std_logic;
    
    -- Sinais para mp_delay
    signal mp_ce_n: std_logic;
    signal mp_we_n: std_logic;
    signal mp_oe_n: std_logic;
    
    -- Contador de tempo de execução
    signal cycle_count: integer := 0;
    signal exec_time_ns: real := 0.0;
    signal execution_active: std_logic := '0';  -- indica se a execução está ativa
    signal first_invalid: std_logic := '0';     -- marca primeira instrução inválida
    
    -- Estatísticas da cache
    signal cache_hits: integer := 0;
    signal cache_misses: integer := 0;
    signal cache_accesses: integer := 0;
    signal cache_cpu_ack_prev: std_logic := '0';  -- Para detectar rising edge
    
    file ARQ : TEXT open READ_MODE is "Test_Program_Allinst_MIPS_MCS.txt";
 
begin
    
    ----------------------------------------------------------------------------
    -- HIERARQUIA DE MEMÓRIA DE DADOS: CPU → Cache L1 → mp_delay
    ----------------------------------------------------------------------------
    
    -- Cache L1 (conectada à CPU)
    Data_cache: l1_cache
        port map (
            clk => ck,
            reset_n => cache_reset_n,
            cpu_addr => cache_cpu_addr,
            cpu_data => cache_cpu_data,
            cpu_ce => cache_cpu_ce,
            cpu_rw => cache_cpu_rw,
            cpu_bw => bw,
            cpu_ack => cache_cpu_ack,
            cpu_hit => cache_cpu_hit,
            mem_addr => cache_mem_addr,
            mem_data => cache_mem_data,
            mem_ce => cache_mem_ce,
            mem_rw => cache_mem_rw,
            mem_ack => cache_mem_ack
        );
    
    -- mp_delay_with_ack (memória lenta conectada à cache)
    Data_mp: mp_delay_with_ack
        generic map(
            LATENCY => 16,
            MEMORY_SIZE => 2048,
            START_ADDRESS => x"10010000"
        )
        port map (
            clk => ck,
            reset_n => cache_reset_n,
            ce_n => mp_ce_n,
            we_n => mp_we_n,
            oe_n => mp_oe_n,
            bw => bw,
            address => cache_mem_addr,
            data => cache_mem_data,
            ack => cache_mem_ack
        );
    
    -- Adaptação dos sinais cache ↔ mp_delay
    mp_ce_n <= not cache_mem_ce;
    mp_we_n <= cache_mem_rw;  -- rw=1 (read) → we_n=1, rw=0 (write) → we_n=0
    mp_oe_n <= not cache_mem_rw;  -- rw=1 (read) → oe_n=0, rw=0 (write) → oe_n=1
    
    ----------------------------------------------------------------------------
    -- MEMÓRIA DE INSTRUÇÕES (sem cache, acesso direto)
    ----------------------------------------------------------------------------
                                             
    Instr_mem: RAM_mem
               generic map( START_ADDRESS => x"00400000" )
               port map (ce_n=>Ice_n, we_n=>Iwe_n, oe_n=>Ioe_n, bw=>'1', address=>Iadress, data=>Idata);
    
    ----------------------------------------------------------------------------
    -- Adaptação de sinais da CPU para a Cache L1 (memória de dados)
    ----------------------------------------------------------------------------
    cache_reset_n <= not rstCPU;
    cache_cpu_addr <= d_cpu_address;
    cache_cpu_ce <= ce when rstCPU='0' else '0';
    cache_cpu_rw <= rw;
    
    -- Dados bidirecionais: CPU ↔ Cache
    -- Escrita: CPU → Cache
    cache_cpu_data <= data_cpu when (ce='1' and rw='0' and rstCPU='0') else (others=>'Z');
    -- Leitura: Cache → CPU
    data_cpu <= cache_cpu_data when (ce='1' and rw='1' and rstCPU='0') else (others=>'Z');
    
    -- HOLD: pausa CPU quando cache não está pronta (aguardando miss)
    -- Mantém hold da leitura de instruções + hold do acesso à cache
    process(rst, ck)
        variable em_count: std_logic;
        variable count: integer;
        variable cache_wait: std_logic;
    begin
        if rst = '1' then
            hold <= '0';
            em_count := '0';
            cache_wait := '0';
        elsif ck'event and ck = '0' then
            -- Hold para leitura de instruções (readInst)
            if readInst = '1' then
                if em_count = '0' then
                    count := 0;
                    hold <= '1';
                    em_count := '1';
                else
                    if count = 15 then
                       hold <= '0';
                       em_count := '0';
                    else
                       count := count + 1;
                    end if;
                end if;
            -- Hold para esperar ack da cache (quando CPU acessa memória)
            elsif ce = '1' and rstCPU = '0' then
                if cache_cpu_ack = '0' then
                    hold <= '1';  -- CPU espera cache
                else
                    hold <= '0';  -- Cache respondeu
                end if;
            else
                hold <= '0';
            end if;
        end if; 
    end process;
                                   
    ----------------------------------------------------------------------------
    -- sinais para adaptar a memória de instruções ao processador
    ----------------------------------------------------------------------------
    
	Ice_n <= '0';                        
    Ioe_n <= '1' when rstCPU='1' else '0';           -- impede leitura enquanto está escrevendo
    Iwe_n <= '0' when go_i='1'   else '1';           -- escrita durante a leitura do arquivo
    
    Iadress <= tb_add  when rstCPU='1' else i_cpu_address;
    Idata   <= tb_data when rstCPU='1' else (others => 'Z'); 
  

    cpu: entity work.MIPS_S port map
	(
		clock=>ck, reset=>rstCPU, hold=>hold,
		i_address => i_cpu_address,
		instruction => Idata,
		ce=>ce, rw=>rw, bw=>bw,
		readInst => readInst,
		d_address => d_cpu_address,
		data => data_cpu
	); 

    rst <='1', '0' after 15 ns;       -- gera o sinal de reset global 

    process                          -- gera o clock global 
        begin
        ck <= '1', '0' after 10 ns;
        wait for 20 ns;
    end process;

    ----------------------------------------------------------------------------
    -- Contador de ciclos de clock e tempo de execução
    ----------------------------------------------------------------------------
    process(ck, rstCPU)
    begin
        if rstCPU = '1' then
            cycle_count <= 0;
            exec_time_ns <= 0.0;
            execution_active <= '0';
            first_invalid <= '0';
            cache_hits <= 0;
            cache_misses <= 0;
            cache_accesses <= 0;
            cache_cpu_ack_prev <= '0';
        elsif rising_edge(ck) then
            -- Inicia contagem após o reset
            if execution_active = '0' then
                execution_active <= '1';
                report "========================================";
                report "INICIANDO CONTAGEM DE TEMPO DE EXECUCAO";
                report "COM CACHE L1 + MP_DELAY (LATENCY=16)";
                report "========================================";
            end if;
            
            cycle_count <= cycle_count + 1;
            exec_time_ns <= real(cycle_count + 1) * 20.0; -- período de clock = 20 ns
            
            -- Detecta rising edge de cache_cpu_ack para contar acessos
            cache_cpu_ack_prev <= cache_cpu_ack;
            if cache_cpu_ack = '1' and cache_cpu_ack_prev = '0' then
                cache_accesses <= cache_accesses + 1;
                if cache_cpu_hit = '1' then
                    cache_hits <= cache_hits + 1;
                else
                    cache_misses <= cache_misses + 1;
                end if;
            end if;
            
            -- Exibe o tempo a cada 1000 ciclos
            if (cycle_count + 1) mod 1000 = 0 then
                report "Ciclos: " & integer'image(cycle_count + 1) & 
                       " | Tempo: " & real'image(exec_time_ns) & " ns" &
                       " | Cache: " & integer'image(cache_hits) & " hits, " &
                       integer'image(cache_misses) & " misses";
            end if;
        end if;
    end process;
    
    -- Processo para detectar fim da execução (quando cache para de ser acessada)
    process
        variable last_valid_cycle: integer := 0;
        variable last_valid_time: real := 0.0;
        variable last_cache_accesses: integer := 0;
        variable exec_time_us: real := 0.0;
        variable exec_time_ms: real := 0.0;
        variable exec_time_s: real := 0.0;
        variable hit_rate: real := 0.0;
        variable miss_rate: real := 0.0;
        variable stall_count: integer := 0;
    begin
        wait until rstCPU = '0';  -- espera o processador iniciar
        wait for 200 ns;           -- aguarda estabilização
        
        -- Loop principal de monitoramento
        loop
            wait until rising_edge(ck);
            
            -- Verifica se houve novos acessos à cache
            if cache_accesses /= last_cache_accesses then
                -- Houve acesso, atualiza referências
                last_cache_accesses := cache_accesses;
                last_valid_cycle := cycle_count;
                last_valid_time := exec_time_ns;
                stall_count := 0;
            else
                -- Sem novos acessos, incrementa contador
                stall_count := stall_count + 1;
            end if;
            
            -- Se ficou 50000 ciclos sem acessar cache, considera que terminou
            if stall_count >= 50000 then
                -- Nenhum ciclo novo, pode ter terminado
                -- Calcula tempo em diferentes unidades
                exec_time_us := last_valid_time / 1000.0;
                exec_time_ms := exec_time_us / 1000.0;
                exec_time_s := exec_time_ms / 1000.0;
                
                -- Calcula taxas de hit/miss
                if cache_accesses > 0 then
                    hit_rate := (real(cache_hits) / real(cache_accesses)) * 100.0;
                    miss_rate := (real(cache_misses) / real(cache_accesses)) * 100.0;
                else
                    hit_rate := 0.0;
                    miss_rate := 0.0;
                end if;
                
                report "========================================";
                report "     RESUMO DA EXECUCAO COM CACHE L1";
                report "========================================";
                report "Total de ciclos: " & integer'image(last_valid_cycle);
                report "Tempo total (ns): " & real'image(last_valid_time) & " ns";
                report "Tempo total (us): " & real'image(exec_time_us) & " us";
                report "Tempo total (ms): " & real'image(exec_time_ms) & " ms";
                report "Tempo total (s):  " & real'image(exec_time_s) & " s";
                report "----------------------------------------";
                report "ESTATISTICAS DA CACHE L1:";
                report "Total de acessos: " & integer'image(cache_accesses);
                report "Cache hits:       " & integer'image(cache_hits) & 
                       " (" & real'image(hit_rate) & " %)";
                report "Cache misses:     " & integer'image(cache_misses) &
                       " (" & real'image(miss_rate) & " %)";
                report "========================================";
                exit;
            end if;
        end loop;
    end process;

    
    ----------------------------------------------------------------------------
    -- Este processo carrega a mem�ria de instru��es e a mem�ria de dados
    -- durante o per�odo que o reset fica ativo
    --
    --
    --   O PROCESSO ABAIXO � UM PARSER PARA LER C�DIGO GERADO PELO MARS NO
    --   SEGUINTE FORMATO:
    --
    --      Text Segment
    --      0x00400000        0x3c011001  lui $1, 4097 [d2]               ; 16: la    $t0, d2
    --      0x00400004        0x34280004  ori $8, $1, 4 [d2]
    --      0x00400008        0x8d080000  lw $8, 0($8)                    ; 17: lw    $t0,0($t0)
    --      .....
    --      0x00400048        0x0810000f  j 0x0040003c [loop]             ; 30: j     loop
    --      0x0040004c        0x01284821  addu $9, $9, $8                 ; 32: addu $t1, $t1, $t0
    --      0x00400050        0x08100014  j 0x00400050 [x]                ; 34: j     x
    --      Data Segment
    --      0x10010000        0x0000faaa  0x00000083  0x00000000  0x00000000
    --
    ----------------------------------------------------------------------------
    process
        variable ARQ_LINE : LINE;
        variable line_arq : string(1 to TAM_LINHA);
        variable code     : boolean;
        variable i, address_flag : integer;
    begin  
        go_i <= '0';
        go_d <= '0';
        rstCPU <= '1';           -- segura o processador durante a leitura do arquivo
        code:=true;              -- valor default de code � true (leitura de instru��es)
                                 
        wait until rst = '1';
        
        while NOT (endfile(ARQ)) loop    -- INCIO DA LEITURA DO ARQUIVO CONTENDO INSTRU��ES E DADOS -----
            readFileLine(ARQ, line_arq);            
            if line_arq(1 to 12)="Text Segment" then 
                   code:=true;                     -- instru��es 
            elsif line_arq(1 to 12)="Data Segment" then
                   code:=false;                    -- dados
            else 
               i := 1;                  -- LEITURA DE LINHA - analisar o la�o abaixo para entender 
               address_flag := 0;       -- para INSTRU��ES  um par (end,inst)
                                        -- para DADOS aceita (end dado 0 dado 1 dado 2 ....)
               loop                                     
                  if line_arq(i) = '0' and line_arq(i+1) = 'x' then -- encontrou indica�� de n�mero hexa: '0x'
                         i := i + 2;
                         if address_flag=0 then
                               for w in 0 to 7 loop
                                   tb_add( (31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8; 
                               address_flag := 1;
                         else
                               for w in 0 to 7 loop
                                   tb_data( (31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8;
                               
                               wait for 0.1 ns;
                               
                               if code=true then go_i <= '1';    
                               -- O sinal go_i habilita escrita na mem�ria de instru��es
                                            else go_d <= '1';    
                               -- O sinal go_d habilita escrita na mem�ria de dados
                               end if; 
                               
                               wait for 0.1 ns;
                               
                               tb_add <= tb_add + 4; -- OK, consigo ler mais de um dado por linha!
                               go_i <= '0';
                               go_d <= '0'; 
                               
                               address_flag := 2;    -- sinaliza que j� leu o conte�do do endere�o;

                         end if;
                  end if;
                  i := i + 1;
                  
                  -- sai da linha quando chegou no seu final OU j� leu par (endereo, instru��o) 
                  --    no caso de instru��es
                  exit when i=TAM_LINHA or (code=true and address_flag=2);
               end loop;
            end if;
            
        end loop;       -- FINAL DA LEITURA DO ARQUIVO CONTENDO INSTRU��ES E DADOS -----
        
        rstCPU <= '0' after 2 ns;   -- libera o processador para executar o programa
        wait for 4 ns;              -- espera um pouco antes de come�ar a esperar pelo rst de novo
        wait until rst = '1';       -- Se isto acontecer come�a de novo!!
        
    end process;
    
end cpu_tb;