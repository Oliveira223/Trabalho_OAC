# poor_spatial_locality.asm
# Programa MIPS com péssima localidade espacial: acessos com grande stride.
# Percorre um vetor mas salta muitos bytes entre acessos (stride grande),
# causando muitos misses de cache de linha.

    .data
    .align 2
# vetor grande: 1024 acessos com stride de 64 palavras (64*4 = 256 bytes)
.vector_space: .space 262144   # 1024 * 256 bytes = 256 KB (suficiente para exemplo)

    .text
    .globl main
main:
    la   $t4, vector_space   # ponteiro que será incrementado por stride
    li   $t0, 1024           # número de acessos

loop:
    lw   $t5, 0($t4)        # acesso com stride -> pobre localidade espacial
    addi $t4, $t4, 256      # stride em bytes (64 palavras * 4)
    addi $t0, $t0, -1
    bne  $t0, $zero, loop

end:
    j end
