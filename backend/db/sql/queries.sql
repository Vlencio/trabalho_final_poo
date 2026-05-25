-- ============================================================
-- 10 CONSULTAS SQL com JOIN, GROUP BY e HAVING
-- ============================================================


-- 1) Modelos de moto com pelo menos 2 conversas, ordenados por procura
SELECT
    mm.nome                       AS modelo,
    mm.categoria,
    COUNT(c.id)                   AS total_conversas,
    ROUND(AVG(c.lead_score), 2)   AS score_medio_interesse
FROM motorcycle_models mm
INNER JOIN conversations c ON c.model_id = mm.id
GROUP BY mm.id, mm.nome, mm.categoria
HAVING COUNT(c.id) >= 2
ORDER BY total_conversas DESC;


-- 2) Vendedores com mais de 3 leads qualificadas
SELECT
    s.nome        AS vendedor,
    COUNT(c.id)   AS leads_qualificadas
FROM sellers s
INNER JOIN conversations c ON c.seller_id = s.id
WHERE c.status = 'qualified'
GROUP BY s.id, s.nome
HAVING COUNT(c.id) > 3
ORDER BY leads_qualificadas DESC;


-- 3) Taxa de qualificacao dos vendedores com pelo menos 5 atendimentos
SELECT
    s.nome                                                          AS vendedor,
    COUNT(c.id)                                                     AS total_atendimentos,
    SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END)         AS qualificadas,
    ROUND(
        100.0 * SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END)
              / COUNT(c.id), 2
    )                                                               AS taxa_pct
FROM sellers s
INNER JOIN conversations c ON c.seller_id = s.id
GROUP BY s.id, s.nome
HAVING COUNT(c.id) >= 5
ORDER BY taxa_pct DESC;


-- 4) Usuarios mais ativos (5 ou mais mensagens enviadas)
SELECT
    u.nome,
    u.wa_id,
    COUNT(m.id)                          AS mensagens_enviadas,
    COUNT(DISTINCT m.conversation_id)    AS total_conversas
FROM users u
INNER JOIN conversations c ON c.user_id        = u.id
INNER JOIN messages m      ON m.conversation_id = c.id
WHERE m.role = 'user'
GROUP BY u.id, u.nome, u.wa_id
HAVING COUNT(m.id) >= 5
ORDER BY mensagens_enviadas DESC;


-- 5) Conversas que foram transferidas mais de uma vez
SELECT
    c.id           AS conversation_id,
    u.nome         AS cliente,
    COUNT(he.id)   AS total_handoffs
FROM conversations c
INNER JOIN users u           ON u.id              = c.user_id
INNER JOIN handoff_events he ON he.conversation_id = c.id
GROUP BY c.id, u.nome
HAVING COUNT(he.id) > 1
ORDER BY total_handoffs DESC;


-- 6) Slots de qualificacao coletados em mais de 10 conversas
SELECT
    qs.slot_name,
    COUNT(*)                              AS total_coletas,
    COUNT(DISTINCT qs.conversation_id)    AS conversas_distintas
FROM qualification_slots qs
INNER JOIN conversations c ON c.id = qs.conversation_id
GROUP BY qs.slot_name
HAVING COUNT(DISTINCT qs.conversation_id) > 10
ORDER BY total_coletas DESC;


-- 7) Score medio das conversas por categoria de moto (amostra minima de 3)
SELECT
    mm.categoria,
    COUNT(c.id)                   AS total_conversas,
    ROUND(AVG(c.lead_score), 2)   AS score_medio,
    MAX(c.lead_score)             AS score_max,
    MIN(c.lead_score)             AS score_min
FROM motorcycle_models mm
INNER JOIN conversations c ON c.model_id = mm.id
WHERE c.lead_score IS NOT NULL
GROUP BY mm.categoria
HAVING COUNT(c.id) >= 3
ORDER BY score_medio DESC;


-- 8) Motivos de handoff mais frequentes (mais de 2 ocorrencias)
SELECT
    he.motivo,
    COUNT(*)                          AS ocorrencias,
    COUNT(DISTINCT he.seller_id)      AS vendedores_distintos
FROM handoff_events he
INNER JOIN conversations c ON c.id = he.conversation_id
GROUP BY he.motivo
HAVING COUNT(*) > 2
ORDER BY ocorrencias DESC;


-- 9) Vendedores ativos sem leads nos ultimos 30 dias
SELECT
    s.nome                       AS vendedor,
    COUNT(c.id)                  AS leads_total,
    MAX(c.last_message_at)       AS ultima_interacao
FROM sellers s
LEFT JOIN conversations c ON c.seller_id = s.id
WHERE s.ativo = TRUE
GROUP BY s.id, s.nome
HAVING SUM(CASE
              WHEN c.last_message_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
              THEN 1 ELSE 0
           END) = 0
ORDER BY ultima_interacao NULLS FIRST;


-- 10) Estatisticas por mes (meses com mais de 5 conversas iniciadas)
SELECT
    EXTRACT(YEAR  FROM c.started_at)                          AS ano,
    EXTRACT(MONTH FROM c.started_at)                          AS mes,
    COUNT(*)                                                  AS total_conversas,
    SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END)   AS qualificadas,
    ROUND(AVG(c.lead_score), 2)                               AS score_medio
FROM conversations c
INNER JOIN users u ON u.id = c.user_id
GROUP BY EXTRACT(YEAR FROM c.started_at), EXTRACT(MONTH FROM c.started_at)
HAVING COUNT(*) > 5
ORDER BY ano DESC, mes DESC;