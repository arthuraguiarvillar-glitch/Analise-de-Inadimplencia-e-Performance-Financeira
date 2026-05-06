# Análise de Inadimplência e Performance Financeira

Análise de uma carteira de crédito simulada com foco em inadimplência, aging de parcelas, exposição financeira por segmento e correlação entre score de crédito e comportamento de pagamento.

---

## Sobre o Dataset

| Info | Valor |
| --- | --- |
| Fonte | Dataset simulado — carteira de crédito fintech |
| Total de registros | 8 pagamentos / 5 contratos / 5 clientes |
| Período | 2022 a 2025 |
| Variáveis | Valor, Produto, Score de Crédito, Dias de Atraso, UF, Segmento (PF/PJ), Status do Contrato |

---

## Ferramentas Utilizadas

- **SQL (PostgreSQL)** — modelagem, ETL e queries analíticas
- **Excel Avançado** — tabela dinâmica, slicers, formatação condicional
- **Power BI + DAX** — dashboard interativo com 4 páginas e medidas calculadas

---


## Etapas Realizadas

### Modelagem e ETL (SQL)

- Criação do modelo relacional com 3 tabelas: `clientes`, `contratos`, `pagamentos`
- View enriquecida `vw_pagamentos_enriquecidos` consolidando dados das 3 tabelas
- Limpeza de dados: identificação de registros inconsistentes e recalculo de `dias_atraso`
- Dicionário de dados documentado diretamente no script

### KPIs Analíticos

- Taxa de inadimplência por produto
- Exposição financeira em risco por UF
- Distribuição de aging em faixas (01-30 / 31-60 / 61-90 / 90+ dias)
- Ticket médio e volume por segmento (PF vs PJ)
- Identificação dos clientes de maior risco
- Tendência mensal de pagamentos (série temporal)

### Excel

- Importação da view SQL exportada como CSV
- Coluna auxiliar de `faixa_atraso` com `SE` aninhado
- Tabela dinâmica de aging por produto
- Formatação condicional por faixa de atraso
- Dashboard com 4 gráficos e segmentações interativas (slicers)

### Power BI

- Relacionamentos entre as 3 tabelas no modelo estrela
- Tabela `Calendário` com DAX para inteligência de tempo
- 6 medidas DAX: Taxa de Inadimplência, Valor em Risco, Ticket Médio, Atraso Médio, Adimplência do Mês e variação MoM
- 4 páginas: Visão Executiva, Análise de Inadimplência, Análise de Clientes, Drill-Through por Contrato

---

## Principais Descobertas

### Concentração de Risco em PJ

- Clientes PJ representam **40% da base**, mas concentram **92% do valor inadimplente**
- Isso indica risco assimétrico — o volume financeiro por contrato PJ é muito superior ao PF

### Score de Crédito como Preditor

- **100% das parcelas na faixa crítica (90+ dias)** pertencem a clientes com score abaixo de 500
- O score se mostrou um preditor confiável de inadimplência dentro da carteira analisada

### Desempenho por Produto

| Produto | Taxa de Inadimplência |
| --- | --- |
| Consignado | 0,0% |
| Crédito Pessoal | 50,0% |
| Capital de Giro | 100,0% |

- **Consignado** apresenta zero inadimplência — padrão esperado pelo desconto em folha
- **Capital de Giro** concentra todo o risco da carteira simulada

### Aging da Carteira

| Faixa de Atraso | Parcelas | Valor em Aberto |
| --- | --- | --- |
| Sem atraso | 4 | R$ 0 |
| 01–30 dias | 1 | R$ 1.167 |
| 31–90 dias | 1 | R$ 708 |
| 90+ dias | 2 | R$ 20.000 |

---

## Autor

Feito por **Arthur Villar** — estudante de Data Science.
