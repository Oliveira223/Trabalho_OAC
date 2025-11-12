# mixed_locality.asm
# Programa MIPS que mistura localidade espacial e temporal.
# Um pequeno bloco (janela) de palavras é acessado repetidamente.

    .data
    .align 2
# bloco pequeno que será reutilizado muitas vezes
block: .space 64       # 16 palavras (64 bytes) - cabe em poucas linhas de cache

    .text
    .globl main
main:
    la   $s0, block      # base do bloco
    li   $s1, 1000       # número de repetições do bloco (loop externo)

outer_loop:
    li   $t0, 0          # contador interno (acessa 8 palavras por iteração)
inner_loop:
    lw   $t1, 0($s0)
    lw   $t2, 4($s0)
    lw   $t3, 8($s0)
    lw   $t4, 12($s0)
    lw   $t5, 16($s0)
    lw   $t6, 20($s0)
    lw   $t7, 24($s0)
    lw   $t8, 28($s0)
    addi $t0, $t0, 1
    bne  $t0, 8, inner_loop

    addi $s1, $s1, -1
    bne  $s1, $zero, outer_loop

end:
    j end
