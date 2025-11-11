// wave.do - configura a janela de waveform para o testbench tb_cache_l1
#Adiciona sinais essenciais à waveform (ajuste caminhos/sinais conforme necessário)

#limpa janela de waves atual
wave clear

// adiciona recursivamente todos os sinais do testbench
add wave -r /tb_cache_l1/*

// organiza e aplica zoom inicial
view wave
wave zoom full

// opções de tempo
# set the timeformat to ns
# timeformat -unit ns -precision 1

// fim
