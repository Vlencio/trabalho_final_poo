-- VIEW 1: Performance dos vendedores
-- Mostra total de leads, qualificadas, perdidas, score medio e taxa
CREATE OR REPLACE VIEW vw_seller_performance AS
SELECT
    s.id AS seller_id,
    s.nome AS vendedor,
    s.ativo,
    COUNT(c.id) AS total_leads,
    SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END) AS leads_qualificadas,
    SUM(CASE WHEN c.status = 'cold'      THEN 1 ELSE 0 END) AS leads_perdidas,
    ROUND(AVG(c.lead_score), 2) AS score_medio,
    CASE
        WHEN COUNT(c.id) > 0 THEN
            ROUND(100.0 * SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END) / COUNT(c.id), 2)
        ELSE 0
    END AS taxa_qualificacao_pct
FROM sellers s
LEFT JOIN conversations c ON c.seller_id = s.id
GROUP BY s.id, s.nome, s.ativo;


-- VIEW 2: Conversas ativas com info do cliente, modelo e vendedor
CREATE OR REPLACE VIEW vw_active_conversations AS
SELECT
    c.id AS conversation_id,
    u.nome AS cliente,
    u.wa_id,
    mm.nome AS modelo_interesse,
    mm.categoria,
    s.nome AS vendedor_atribuido,
    c.status,
    c.lead_score,
    COUNT(m.id) AS total_mensagens,
    SUM(CASE WHEN m.role = 'user'      THEN 1 ELSE 0 END) AS msgs_cliente,
    SUM(CASE WHEN m.role = 'assistant' THEN 1 ELSE 0 END) AS msgs_bot,
    c.started_at,
    c.last_message_at
FROM conversations c
INNER JOIN users u ON u.id  = c.user_id
LEFT  JOIN motorcycle_models mm ON mm.id = c.model_id
LEFT  JOIN sellers s ON s.id  = c.seller_id
LEFT  JOIN messages m ON m.conversation_id = c.id
WHERE c.status IN ('active', 'qualified', 'handoff')
GROUP BY c.id, u.nome, u.wa_id, mm.nome, mm.categoria,
         s.nome, c.status, c.lead_score, c.started_at, c.last_message_at;