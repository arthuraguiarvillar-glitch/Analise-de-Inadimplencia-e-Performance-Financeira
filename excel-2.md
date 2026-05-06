# Excel — Análise de Inadimplência e Performance Financeira

---

## Estrutura do Arquivo

### Aba `base_pagamentos`

| Coluna             | Tipo   | Descrição                                              |
|--------------------|--------|--------------------------------------------------------|
| pagamento_id       | Número | Identificador da parcela                               |
| nome_cliente       | Texto  | Nome do cliente                                        |
| segmento           | Texto  | PF ou PJ                                               |
| uf                 | Texto  | Estado                                                 |
| score_credito      | Número | Score de crédito (0–1000)                              |
| produto            | Texto  | Linha de crédito                                       |
| status_contrato    | Texto  | Ativo / Quitado / Inadimplente / Renegociado           |
| data_vencimento    | Data   | Vencimento da parcela                                  |
| data_pagamento     | Data   | Data efetiva de pagamento                              |
| valor_devido       | Moeda  | Valor da parcela                                       |
| valor_pago         | Moeda  | Valor recebido                                         |
| dias_atraso        | Número | Dias de atraso (negativo = antecipado)                 |
| situacao_pagamento | Texto  | Em dia / Atrasado / Não pago / Antecipado              |

Coluna auxiliar `faixa_atraso` calculada com:

```excel
=SE([@dias_atraso]<=0,"Sem atraso",
  SE([@dias_atraso]<=30,"01-30 dias",
  SE([@dias_atraso]<=60,"31-60 dias",
  SE([@dias_atraso]<=90,"61-90 dias","90+ dias"))))
```

---

### Aba `contratos` *(necessária para ticket médio)*

> **Nota:** Para calcular ticket médio por segmento de forma correta, o arquivo Excel
> deve conter uma segunda aba `contratos` com as colunas `contrato_id`, `segmento` e
> `valor_total` (5 linhas — uma por contrato). O AVERAGEIFS abaixo referencia essa aba.

| Coluna       | Tipo   | Descrição                           |
|--------------|--------|-------------------------------------|
| contrato_id  | Número | Identificador do contrato           |
| segmento     | Texto  | PF ou PJ                            |
| valor_total  | Moeda  | Valor total do contrato             |

---

### Aba `kpis`

| Indicador              | Fórmula                                                                                                           |
|------------------------|-------------------------------------------------------------------------------------------------------------------|
| Contratos inadimplentes | `=COUNTIF(base_pagamentos[status_contrato],"Inadimplente")`                                                      |
| Valor em risco          | `=SUMPRODUCT((base_pagamentos[valor_devido]-base_pagamentos[valor_pago])*(base_pagamentos[valor_devido]-base_pagamentos[valor_pago]>0))` |
| Ticket médio PF         | `=AVERAGEIF(contratos[segmento],"PF",contratos[valor_total])`                                                    |
| Ticket médio PJ         | `=AVERAGEIF(contratos[segmento],"PJ",contratos[valor_total])`                                                    |
| Score médio             | `=AVERAGE(base_pagamentos[score_credito])`                                                                        |
| Atraso médio (dias)     | `=AVERAGEIF(base_pagamentos[situacao_pagamento],"Atrasado",base_pagamentos[dias_atraso])`                        |

> **Correção aplicada — Ticket Médio PF/PJ:**
> A versão anterior usava `AVERAGEIF(base_pagamentos[segmento],"PF",contratos[valor_total])`,
> cruzando duas tabelas com granularidades diferentes (8 linhas de pagamentos × 5 linhas de
> contratos). Isso retorna `#VALOR!` no Excel real porque os vetores têm tamanhos distintos.
> A correção foi referenciar apenas a aba `contratos` nos dois argumentos do AVERAGEIF.
>
> **Correção aplicada — Valor em risco:**
> A versão anterior usava `SUMIF(...,"Não pago",...)`, o que excluía o pagamento parcial de
> João Ferreira (contrato 104, pagou R$600 de R$708,33 — saldo de R$108,33 em aberto).
> A correção usa SUMPRODUCT calculando o saldo residual diretamente.

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

| Condição   | Cor     |
|------------|---------|
| ≤ 0        | Verde   |
| 1–30 dias  | Amarelo |
| 31–90 dias | Laranja |
| > 90 dias  | Vermelho|

Slicers: `uf`, `produto`, `segmento`

---

## Principais Descobertas

- Clientes PJ concentram **92% do valor inadimplente** apesar de representarem 40% da base
- Score abaixo de 500 está presente em **100% das parcelas críticas** (90+ dias)
- Consignado apresenta inadimplência — parcela 1004 (Carlos Lima) está em aberto desde mai/2023
- Capital de Giro responde por **todo o valor em aberto crítico** (R$20.000)
