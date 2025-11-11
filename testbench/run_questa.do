// run_questa.do - compila e executa o testbench tb_cache_l1.v usando Questa
// Execute este .do a partir do diretório testbench (ou passe o caminho completo)

// Compila os fontes Verilog (ajuste caminhos se necessário)
vlog ../src/cache_l1.v tb_cache_l1.v

// Simula o testbench em GUI com waveform automaticamente carregado
vsim work.tb_cache_l1 -do "add wave -r /*; run -all"

// Se quiser rodar em modo batch/console, use:
// vsim -c work.tb_cache_l1 -do "run -all; quit"
