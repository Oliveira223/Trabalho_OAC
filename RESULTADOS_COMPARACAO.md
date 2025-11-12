# Comparação de Performance: MIPS com e sem Cache L1

## Configuração

### Sistema Base (MIPS_MultiCiclo_Hold_Atraso)
- Processador MIPS Multi-Ciclo
- Acesso direto à memória RAM (sem cache)
- Clock: 50 MHz (período = 20 ns)

### Sistema com Cache (MIPS_MultiCiclo_Hold_Atraso_mixed)
- Processador MIPS Multi-Ciclo
- **Cache L1**: 8 linhas × 8 palavras, mapeamento direto
- **Memória principal com latência**: 16 ciclos (320 ns)
- Clock: 50 MHz (período = 20 ns)
- Política: Write-through + Write-allocate

## Resultados da Simulação

### Cache L1 - Estatísticas
```
Total de acessos:  1224
Cache hits:        1160  (94.77%)
Cache misses:      64    (5.23%)
```

### Análise

#### Taxa de Acerto (Hit Rate): 94.77%
- Excelente taxa de acerto, indicando boa localidade espacial e temporal
- A cada 100 acessos, apenas ~5 precisam buscar dados da memória lenta

#### Padrão de Acessos Observado
- **Ciclo 1000**: 0 hits, 1 miss (cold miss inicial)
- **Ciclo 2000**: 14 hits, 2 misses
- **Ciclo 3000**: 35 hits, 2 misses
- **Ciclo 214000**: 1160 hits, 64 misses (estabilizou)

A evolução mostra que após os misses compulsórios iniciais (cold misses), 
o programa apresenta alta localidade, aproveitando bem a cache.

## Conclusões

### Benefícios da Cache L1

1. **Redução de Latência**:
   - Hits são atendidos em **1 ciclo**
   - Misses requerem **16 ciclos** para buscar bloco completo (8 palavras)
   - Com 94.77% de hits, a maioria dos acessos é extremamente rápida

2. **Impacto no Desempenho**:
   - Sem cache: Todos os acessos à memória levam 1 ciclo (memória rápida)
   - Com cache: 94.77% dos acessos = 1 ciclo, 5.23% = 16 ciclos

3. **Eficiência do Bloco**:
   - Cache utiliza blocos de 8 palavras
   - Após cada miss, próximos 7 acessos sequenciais têm alta probabilidade de hit
   - Apropriado para código e dados com boa localidade espacial

### Observações

- A implementação usa **mapeamento direto** (8 linhas), simples mas eficiente
- **Write-through** garante consistência mas pode gerar tráfego adicional
- **Write-allocate** traz o bloco para cache mesmo em escritas
- Latência de 16 ciclos simula memória realista (DRAM típica)

### Possíveis Melhorias

1. Aumentar número de linhas da cache (reduzir conflitos)
2. Implementar cache associativa (2-way, 4-way)
3. Usar write-back em vez de write-through (reduzir tráfego)
4. Adicionar cache de instruções separada (arquitetura Harvard)

---

**Data da análise**: 12 de novembro de 2025  
**Ferramenta**: ModelSim/Questa 2025.2  
**Linguagens**: VHDL + SystemVerilog (mixed-language)
