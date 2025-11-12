Testbench para cache_l1

Arquivos nesta pasta:
- tb_cache_l1.v      : Testbench Verilog (já presente)
- run_questa.do      : DO file para compilar e abrir a simulação no Questa
- run_questa.ps1     : Script PowerShell que chama o DO (útil no Windows)

Como usar (Questa / ModelSim)
1) Abra PowerShell e vá para a pasta do testbench:
   cd E:\CODES\AOC\Trabalho2-Pedro\testbench

2) Execute o DO diretamente no Questa (GUI):
   vsim -do .\run_questa.do

   Ou abra o Questa e execute o DO dentro do prompt do vsim:
   vsim
   do run_questa.do

3) Alternativa (via PowerShell script):
   .\run_questa.ps1

Notas importantes
- Os caminhos no DO assumem que você está executando a partir de `testbench` e que o arquivo fonte do cache está em `..\src\cache_l1.v`.
- Se preferir compilar todos os fontes Verilog do projeto use:
    vlog ..\src\*.v ..\testbench\*.v

- O testbench gera tb_cache_l1.vcd; no Questa você verá as formas de onda diretamente (ou pode abrir o VCD com GTKWave).
- Se receber erro "vlog/vsim não encontrado", abra a "Questa Command Prompt" ou adicione o binário do Questa ao PATH.

Se quiser, eu posso:
- adaptar o DO para compilar também VHDL do diretório `MIPS_MultiCiclo_Hold_Atraso` (usar `vcom`),
- adicionar um caso de escrita ao testbench, ou
- gerar um script .bat para uso rápido no Windows.
