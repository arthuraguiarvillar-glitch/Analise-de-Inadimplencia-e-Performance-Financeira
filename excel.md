# Excel — Análise de Inadimplência e Performance Financeira

---

## Estrutura do Arquivo

### Aba `base_pagamentos`


| Coluna | Tipo | Descrição |
| --- | --- | --- |
| pagamento_id | Número | Identificador da parcela |
| nome_cliente | Texto | Nome do cliente |
| segmento | Texto | PF ou PJ |
| uf | Texto | Estado |
| score_credito | Número | Score de crédito (0–1000) |
| produto | Texto | Linha de crédito |
| status_contrato | Texto | Ativo / Quitado / Inadimplente / Renegociado |
| data_vencimento | Data | Vencimento da parcela |
| data_pagamento | Data | Data efetiva de pagamento |
| valor_devido | Moeda | Valor da parcela |
| valor_pago | Moeda | Valor recebido |
| dias_atraso | Número | Dias de atraso (negativo = antecipado) |
| situacao_pagamento | Texto | Em dia / Atrasado / Não pago / Antecipado |

Coluna auxiliar `faixa_atraso` calculada com:
```
=SE([@dias_atraso]<=0,"Sem atraso",
  SE([@dias_atraso]<=30,"01-30 dias",
  SE([@dias_atraso]<=60,"31-60 dias",
  SE([@dias_atraso]<=90,"61-90 dias","90+ dias"))))
```

---

### Aba `kpis`

| Indicador | Fórmula |
| --- | --- |
| Contratos inadimplentes | `=COUNTIF(base_pagamentos[status_contrato],"Inadimplente")` |
| Valor em risco | `=SUMIF(base_pagamentos[situacao_pagamento],"Não pago",base_pagamentos[valor_devido])` |
| Ticket médio PF | `=AVERAGEIF(base_pagamentos[segmento],"PF",contratos[valor_total])` |
| Ticket médio PJ | `=AVERAGEIF(base_pagamentos[segmento],"PJ",contratos[valor_total])` |
| Score médio | `=AVERAGE(base_pagamentos[score_credito])` |
| Atraso médio (dias) | `=AVERAGEIF(base_pagamentos[situacao_pagamento],"Atrasado",base_pagamentos[dias_atraso])` |

---

### Aba `aging`
Tabela dinâmica com:
- Linhas: `faixa_atraso`
- Colunas: `produto`
- Valores: `SOMA(valor_devido)` e `CONTAGEM(pagamento_id)`

---

### Aba `dashboard`

Gráficos:
- **Rosca** — proporção de situação de pagamento
- **Barras empilhadas** — volume por produto e status
- **Linha** — série temporal de volume recebido mês a mês
- **Dispersão** — score de crédito × % de atraso

Formatação condicional na coluna `dias_atraso`:

| Condição | Cor |
| --- | --- |
| ≤ 0 | Verde |
| 1–30 dias | Amarelo |
| 31–90 dias | Laranja |
| > 90 dias | Vermelho |

Slicers: `uf`, `produto`, `segmento`

---

## Principais Descobertas

- Clientes PJ concentram **92% do valor inadimplente** apesar de representarem 40% da base
- Score abaixo de 500 está presente em **100% das parcelas críticas** (90+ dias)
- Consignado apresenta **0% de inadimplência** — produto mais saudável da carteira
- Capital de Giro responde por **todo o valor em aberto crítico**
