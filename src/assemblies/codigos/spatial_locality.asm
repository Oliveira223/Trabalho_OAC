# spatial_locality.asm
# Programa MIPS que demonstra boa localidade espacial.
# Percorre um vetor de forma sequencial (acessos contíguos).

    .data
    .align 2
array: .space 4096     # espaço para 1024 palavras (1024 * 4 = 4096 bytes)

    .text
    .globl main
main:
    la   $t0, array      # ponteiro pro início do vetor
    li   $t1, 1024       # número de palavras a acessar
    li   $t2, 0          # sum

loop:
    lw   $t3, 0($t0)     # acesso sequencial -> boa localidade espacial
    addu $t2, $t2, $t3
    addi $t0, $t0, 4     # avança para próxima palavra
    addi $t1, $t1, -1
    bne  $t1, $zero, loop

end:
    nop
    j end
