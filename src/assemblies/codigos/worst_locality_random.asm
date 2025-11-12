# worst_locality_random.asm
# Programa MIPS com padrão de acesso pseudorandomico sobre um vetor grande.
# Gera índices com um LCG (linear congruential generator) e carrega palavras
# em posições espalhadas pela memória — padrão ruim para caches.

    .data
    .align 2
# vetor grande: 16384 palavras -> 65536 bytes
big_array: .space 65536

    .text
    .globl main
main:
    la   $s1, big_array      # base do vetor
    li   $s2, 16384          # tamanho do vetor (número de palavras)
    li   $s3, 10000          # número de iterações (acessos)
    li   $s0, 12345          # seed inicial

loop:
    # s0 = s0 * 1664525 + 1013904223  (LCG parameters)
    li   $t0, 1664525
    mult $s0, $t0
    mflo $s0
    li   $t1, 1013904223
    addu $s0, $s0, $t1

    # index = (s0 >> 16) & (s2-1)  -> limita ao range [0, s2-1]
    srl  $t2, $s0, 16
    li   $t3, 16383          # mask = 16384 - 1 (14 bits)
    and  $t2, $t2, $t3

    # endereço = base + index*4
    sll  $t2, $t2, 2         # index * 4 (byte offset)
    addu $t2, $t2, $s1
    lw   $t4, 0($t2)         # acesso pseudo-aleatório -> péssima localidade

    addi $s3, $s3, -1
    bne  $s3, $zero, loop

end:
    j end
