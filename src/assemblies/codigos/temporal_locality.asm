# temporal_locality.asm
# Programa MIPS que demonstra boa localidade temporal.
# O loop acessa repetidamente a mesma palavra na memória.

    .data
    .align 2
datum: .word 0x12345678

    .text
    .globl main
main:
    la   $t0, datum      # ponteiro para o dado único
    li   $t1, 10000      # contador de iterações
    li   $t2, 0          # sum (para evitar otimização)

loop:
    lw   $t3, 0($t0)     # sempre carrega a mesma palavra -> alta localidade temporal
    addu $t2, $t2, $t3
    addi $t1, $t1, -1
    bne  $t1, $zero, loop

end:
    nop
    j end
