Resumo

Esta pasta é uma cópia do diretório `MIPS_MultiCiclo_Hold_Atraso` preparada para simular em mixed-language (VHDL + SystemVerilog) com Questa/ModelSim.

O arquivo `RAM_mem` (originalmente implementado em VHDL dentro do testbench) foi removido da implementação VHDL e substituído por um módulo SystemVerilog `RAM_mem.sv`. Assim o `CPU_tb.vhd` (cópia em `MIPS-MC_SingleEdge_tb.vhd`) instancia `RAM_mem` como antes, porém a implementação vem do SystemVerilog compilado por `vlog`.

Arquivos importantes nesta pasta:
- `MIPS-MC_SingleEdge.vhd`  - cópia do processador e módulos VHDL (parte do conteúdo pode estar truncado neste snapshot)
- `MIPS-MC_SingleEdge_tb.vhd` - testbench (a arquitetura VHDL da RAM foi removida; a entity RAM_mem permanece)
- `mult_div.vhd` - módulo multiplicador/divisor
- `RAM_mem.sv` - SystemVerilog replacement for the VHDL RAM (same portlist)
- `l1_cache.sv` - skeleton L1 cache (SV) to be used when wiring cache into the top-level
- `mp_delay.sv` - skeleton MP with LATENCY parameter
- `sim.do` - script updated to compile SystemVerilog (`vlog`) then VHDL (`vcom`) and run `vsim`
- `Test_Program_Allinst_MIPS_MCS.txt` - program used by testbench
- `wave.do` - waveform setup

Como rodar (ModelSim/Questa)
1) Abrir ModelSim/Questa e rodar o `sim.do`:

   vsim -do sim.do

(O `sim.do` já chama `vlog` e `vcom` em ordem apropriada.)

Notas e próximos passos
- Esta cópia não faz alterações profundas no processador. Para que a CPU realmente espere por uma resposta quando a MP tiver atraso (LATENCY), será necessário adaptar o testbench ou o `control_unit` do processador para usar um sinal de ack/hold que venha da memória. Atualmente a interface foi mantida para compatibilidade com o TB original.
- Se quiser que eu atualize o `CPU_tb` para gerar o `hold` durante acessos à memória lenta (usando, por exemplo, um sinal de ack vindo de `mp_delay.sv`), posso modificar o TB para isso.
- Para usar a cache L1 (modo MP+L1) preciso atualizar o TB ou criar um top-level que instancie `l1_cache.sv` e `mp_delay.sv` e exponha a mesma interface de `RAM_mem` para o TB. Posso fazer isso na próxima etapa se desejar.
