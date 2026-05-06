-- ============================================================
-- Análise de Inadimplência e Performance Financeira
-- SQL (PostgreSQL)
-- ============================================================


-- ------------------------------------------------------------
-- 1. MODELAGEM (DDL)
-- ------------------------------------------------------------

CREATE TABLE clientes (
    cliente_id      INT PRIMARY KEY,
    nome            VARCHAR(100),
    segmento        VARCHAR(50),
    uf              CHAR(2),
    data_cadastro   DATE,
    score_credito   INT
);

CREATE TABLE contratos (
    contrato_id     INT PRIMARY KEY,
    cliente_id      INT REFERENCES clientes(cliente_id),
    produto         VARCHAR(50),
    valor_total     NUMERIC(15,2),
    data_inicio     DATE,
    data_vencimento DATE,
    status          VARCHAR(20)
);

CREATE TABLE pagamentos (
    pagamento_id    INT PRIMARY KEY,
    contrato_id     INT REFERENCES contratos(contrato_id),
    data_vencimento DATE,
    data_pagamento  DATE,
    valor_devido    NUMERIC(15,2),
    valor_pago      NUMERIC(15,2),
    dias_atraso     INT
);


-- ------------------------------------------------------------
-- 2. CARGA (DML)
-- ------------------------------------------------------------

INSERT INTO clientes VALUES
(1, 'Ana Souza',      'PF', 'SP', '2021-03-10', 720),
(2, 'Carlos Lima',    'PF', 'RJ', '2020-07-22', 490),
(3, 'Tech Soluções',  'PJ', 'MG', '2019-11-01', 810),
(4, 'João Ferreira',  'PF', 'BA', '2022-01-15', 350),
(5, 'Alfa Comércio',  'PJ', 'PR', '2021-08-30', 640);

INSERT INTO contratos VALUES
(101, 1, 'Crédito Pessoal',   15000.00, '2023-01-01', '2024-01-01', 'Quitado'),
(102, 2, 'Consignado',        28000.00, '2023-03-01', '2025-03-01', 'Ativo'),
(103, 3, 'Capital de Giro',  120000.00, '2022-06-01', '2024-06-01', 'Inadimplente'),
(104, 4, 'Crédito Pessoal',    8500.00, '2023-07-01', '2024-07-01', 'Renegociado'),
(105, 5, 'Capital de Giro',   55000.00, '2023-02-01', '2025-02-01', 'Ativo');

INSERT INTO pagamentos VALUES
(1001, 101, '2023-02-01', '2023-02-01',  1250.00, 1250.00,  0),
(1002, 101, '2023-03-01', '2023-03-05',  1250.00, 1250.00,  4),
(1003, 102, '2023-04-01', '2023-04-01',  1166.67, 1166.67,  0),
(1004, 102, '2023-05-01', NULL,          1166.67, NULL,     NULL),
(1005, 103, '2023-07-01', NULL,         10000.00, NULL,     NULL),
(1006, 103, '2023-08-01', NULL,         10000.00, NULL,     NULL),
(1007, 104, '2023-08-01', '2023-09-15',   708.33,  600.00,  45),
(1008, 105, '2023-09-01', '2023-09-01',  2291.67, 2291.67,  0);


-- ------------------------------------------------------------
-- 3. ETL
-- ------------------------------------------------------------

-- Recalcula dias_atraso nos registros nulos
UPDATE pagamentos
SET dias_atraso = CASE
    WHEN data_pagamento IS NOT NULL
        THEN data_pagamento - data_vencimento
    ELSE
        CURRENT_DATE - data_vencimento
END
WHERE dias_atraso IS NULL;

-- View enriquecida consolidando as 3 tabelas
CREATE OR REPLACE VIEW vw_pagamentos_enriquecidos AS
SELECT
    p.pagamento_id,
    cl.cliente_id,
    cl.nome            AS nome_cliente,
    cl.segmento,
    cl.uf,
    cl.score_credito,
    ct.produto,
    ct.status          AS status_contrato,
    p.data_vencimento,
    p.data_pagamento,
    p.valor_devido,
    COALESCE(p.valor_pago, 0)  AS valor_pago,
    p.dias_atraso,
    CASE
        WHEN p.data_pagamento IS NULL  THEN 'Não pago'
        WHEN p.dias_atraso > 0         THEN 'Atrasado'
        WHEN p.dias_atraso = 0         THEN 'Em dia'
        ELSE                                'Antecipado'
    END AS situacao_pagamento
FROM      pagamentos p
JOIN contratos ct ON p.contrato_id = ct.contrato_id
JOIN clientes  cl ON ct.cliente_id = cl.cliente_id;


-- ------------------------------------------------------------
-- 4. KPIs ANALÍTICOS
-- ------------------------------------------------------------

-- Taxa de inadimplência por produto
SELECT
    ct.produto,
    COUNT(DISTINCT ct.contrato_id)                                AS total_contratos,
    COUNT(DISTINCT CASE WHEN ct.status = 'Inadimplente'
                        THEN ct.contrato_id END)                  AS contratos_inadimplentes,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ct.status = 'Inadimplente'
                                    THEN ct.contrato_id END)
             / NULLIF(COUNT(DISTINCT ct.contrato_id), 0)
    , 2)                                                          AS taxa_inadimplencia_pct
FROM contratos ct
GROUP BY ct.produto
ORDER BY taxa_inadimplencia_pct DESC;


-- Exposição financeira em risco por UF
SELECT
    cl.uf,
    SUM(p.valor_devido)                                    AS total_em_aberto,
    SUM(COALESCE(p.valor_pago, 0))                         AS total_recebido,
    SUM(p.valor_devido) - SUM(COALESCE(p.valor_pago, 0))  AS exposicao_risco
FROM pagamentos p
JOIN contratos ct ON p.contrato_id = ct.contrato_id
JOIN clientes  cl ON ct.cliente_id = cl.cliente_id
WHERE p.data_pagamento IS NULL
GROUP BY cl.uf
ORDER BY exposicao_risco DESC;


-- Aging — distribuição de atraso em faixas
SELECT
    CASE
        WHEN dias_atraso BETWEEN 1  AND 30  THEN '01-30 dias'
        WHEN dias_atraso BETWEEN 31 AND 60  THEN '31-60 dias'
        WHEN dias_atraso BETWEEN 61 AND 90  THEN '61-90 dias'
        WHEN dias_atraso > 90               THEN '90+ dias'
        ELSE                                     'Sem atraso'
    END                                          AS faixa_atraso,
    COUNT(*)                                     AS qtd_parcelas,
    SUM(valor_devido - COALESCE(valor_pago, 0))  AS valor_em_aberto
FROM pagamentos
GROUP BY 1
ORDER BY 1;


-- Ticket médio e score por segmento (PF vs PJ)
SELECT
    cl.segmento,
    COUNT(DISTINCT ct.contrato_id)   AS total_contratos,
    ROUND(AVG(ct.valor_total), 2)    AS ticket_medio,
    SUM(ct.valor_total)              AS volume_total,
    ROUND(AVG(cl.score_credito), 0)  AS score_medio
FROM contratos ct
JOIN clientes cl ON ct.cliente_id = cl.cliente_id
GROUP BY cl.segmento;


-- Clientes com maior risco
SELECT
    cl.cliente_id,
    cl.nome,
    cl.score_credito,
    COUNT(ct.contrato_id)  AS contratos_inadimplentes,
    SUM(ct.valor_total)    AS exposicao_total
FROM clientes cl
JOIN contratos ct ON cl.cliente_id = ct.cliente_id
WHERE ct.status       = 'Inadimplente'
  AND cl.score_credito < 500
GROUP BY cl.cliente_id, cl.nome, cl.score_credito
ORDER BY exposicao_total DESC;


-- Tendência mensal de pagamentos
SELECT
    DATE_TRUNC('month', data_pagamento)  AS mes,
    COUNT(*)                              AS pagamentos_realizados,
    SUM(valor_pago)                       AS volume_recebido,
    ROUND(AVG(dias_atraso), 1)            AS atraso_medio_dias
FROM pagamentos
WHERE data_pagamento IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- ------------------------------------------------------------
-- 5. ANÁLISE EXPLORATÓRIA
-- ------------------------------------------------------------

-- Correlação entre faixa de score e % de atraso
SELECT
    CASE
        WHEN score_credito < 300  THEN 'Baixo (0-299)'
        WHEN score_credito < 600  THEN 'Regular (300-599)'
        WHEN score_credito < 800  THEN 'Bom (600-799)'
        ELSE                           'Excelente (800+)'
    END                                    AS faixa_score,
    COUNT(DISTINCT p.pagamento_id)         AS total_parcelas,
    COUNT(DISTINCT CASE WHEN p.dias_atraso > 0
                        THEN p.pagamento_id END)  AS parcelas_atrasadas,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN p.dias_atraso > 0
                                    THEN p.pagamento_id END)
             / NULLIF(COUNT(DISTINCT p.pagamento_id), 0)
    , 2)                                   AS pct_atraso
FROM vw_pagamentos_enriquecidos p
GROUP BY 1
ORDER BY pct_atraso DESC;


-- Matriz risco x retorno por produto
SELECT
    ct.produto,
    SUM(ct.valor_total)                                           AS volume_carteira,
    SUM(COALESCE(p.valor_pago, 0))                               AS total_recebido,
    ROUND(100.0 * SUM(COALESCE(p.valor_pago, 0))
                / NULLIF(SUM(p.valor_devido), 0), 2)             AS pct_adimplencia,
    ROUND(AVG(CASE WHEN p.dias_atraso > 0
                   THEN p.dias_atraso END), 1)                   AS atraso_medio_inadimplentes
FROM contratos ct
JOIN pagamentos p ON ct.contrato_id = p.contrato_id
GROUP BY ct.produto
ORDER BY volume_carteira DESC;
