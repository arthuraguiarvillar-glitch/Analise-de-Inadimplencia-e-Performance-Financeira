# Power BI — Análise de Inadimplência e Performance Financeira

---

## Modelo de Dados

Conexão via DirectQuery ou importação do CSV exportado do SQL.

```
clientes (1) ──── (N) contratos (1) ──── (N) pagamentos
```

Tabela `Calendário` criada via DAX:

```dax
Calendário =
ADDCOLUMNS(
    CALENDAR(DATE(2020,1,1), DATE(2025,12,31)),
    "Ano",        YEAR([Date]),
    "Mês",        MONTH([Date]),
    "Mês Nome",   FORMAT([Date], "MMMM"),
    "Trimestre",  "T" & QUARTER([Date]),
    "Semana",     WEEKNUM([Date])
)
```

---

## Medidas DAX

```dax
Taxa Inadimplência =
DIVIDE(
    CALCULATE(COUNTROWS(contratos), contratos[status] = "Inadimplente"),
    COUNTROWS(contratos)
) * 100
```

```dax
Valor em Risco =
CALCULATE(
    SUM(pagamentos[valor_devido]),
    pagamentos[data_pagamento] = BLANK()
)
```

```dax
Ticket Médio =
AVERAGEX(contratos, contratos[valor_total])
```

```dax
Atraso Médio Dias =
CALCULATE(
    AVERAGE(pagamentos[dias_atraso]),
    pagamentos[dias_atraso] > 0
)
```

```dax
Adimplência Mês =
DIVIDE(
    CALCULATE(
        COUNTROWS(pagamentos),
        pagamentos[situacao_pagamento] = "Em dia"
    ),
    COUNTROWS(pagamentos)
) * 100
```

```dax
Volume Recebido MoM =
VAR VolumeAtual = [Volume Recebido]
VAR VolumeMesAnterior =
    CALCULATE([Volume Recebido], DATEADD('Calendário'[Date], -1, MONTH))
RETURN
    DIVIDE(VolumeAtual - VolumeMesAnterior, VolumeMesAnterior) * 100
```

---

## Páginas do Relatório

### Página 1 — Visão Executiva
- 4 cards KPI: taxa de inadimplência, valor em risco, ticket médio, score médio
- Gráfico de linhas: evolução mensal de volume recebido
- Gráfico de rosca: distribuição de status dos contratos
- Filtros: ano, segmento, produto

### Página 2 — Análise de Inadimplência
- Mapa do Brasil: taxa de inadimplência por UF
- Gráfico de barras: volume em risco por produto
- Tabela de aging com formatação condicional por faixa
- Gráfico de dispersão: score de crédito × taxa de atraso

### Página 3 — Análise de Clientes
- Tabela: top 10 clientes de maior risco
- Gráfico de barras: distribuição de clientes por faixa de score
- KPIs lado a lado: PF vs PJ
- Segmentação interativa por segmento

### Página 4 — Drill-Through por Contrato
- Histórico de pagamentos do contrato selecionado
- Linha do tempo de parcelas
- Status atual e alertas de risco

---

## Principais Descobertas

- PJ concentra **92% do valor inadimplente** com apenas 40% dos contratos
- Score < 500 está em **100% das parcelas críticas** (90+ dias)
- Consignado: **0% de inadimplência**
- Capital de Giro: **100% de inadimplência** — maior risco da carteira
