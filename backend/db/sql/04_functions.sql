-- ============================================================
-- FUNCTIONS DO PROJETO
-- 4 functions usadas por triggers + 2 functions standalone
-- ============================================================


-- ============================================================
-- FUNCTIONS USADAS POR TRIGGERS
-- (sao chamadas automaticamente pelos triggers em 03_triggers.sql)
-- ============================================================


-- FUNCTION 1: atualiza updated_at quando uma linha de users e modificada
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 2: atualiza last_message_at da conversa quando uma nova
-- mensagem e inserida
CREATE OR REPLACE FUNCTION update_conv_last_message_at()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 3: auditoria automatica de mudancas de score
-- Quando lead_score muda em conversations, registra a mudanca
-- na tabela lead_score_history.
CREATE OR REPLACE FUNCTION fn_audit_lead_score()
RETURNS TRIGGER AS $$
BEGIN
    -- So registra se o score realmente mudou (cobrindo casos com NULL)
    IF (OLD.lead_score IS NULL AND NEW.lead_score IS NOT NULL)
       OR (OLD.lead_score IS NOT NULL AND NEW.lead_score IS NULL)
       OR (OLD.lead_score <> NEW.lead_score) THEN

        INSERT INTO lead_score_history (conversation_id, score_anterior, score_novo)
        VALUES (NEW.id, OLD.lead_score, NEW.lead_score);

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 4: bloqueio de mensagens em conversas com opt-out
-- Se a conversa esta marcada como 'opted_out' (cliente pediu para
-- nao receber mais mensagens), impede que novas mensagens sejam
-- inseridas. Cumpre regra basica da LGPD na camada de banco.
CREATE OR REPLACE FUNCTION fn_block_optout_messages()
RETURNS TRIGGER AS $$
DECLARE
    conv_status VARCHAR(20);
BEGIN
    SELECT status
    INTO   conv_status
    FROM   conversations
    WHERE  id = NEW.conversation_id;

    IF conv_status = 'opted_out' THEN
        RAISE EXCEPTION 'Conversa com opt-out nao aceita novas mensagens.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- FUNCTIONS STANDALONE
-- (podem ser chamadas direto via SELECT pela aplicacao)
-- ============================================================


-- FUNCTION 5: metricas de uma conversa especifica
-- Uso:
--   SELECT * FROM fn_conversation_metrics(1);
CREATE OR REPLACE FUNCTION fn_conversation_metrics(p_conversation_id INTEGER)
RETURNS TABLE (
    total_mensagens BIGINT,
    msgs_cliente    BIGINT,
    msgs_bot        BIGINT,
    score_final     INTEGER,
    status_final    VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(m.id),
        SUM(CASE WHEN m.role = 'user'      THEN 1 ELSE 0 END),
        SUM(CASE WHEN m.role = 'assistant' THEN 1 ELSE 0 END),
        c.lead_score,
        c.status
    FROM conversations c
    LEFT JOIN messages m ON m.conversation_id = c.id
    WHERE c.id = p_conversation_id
    GROUP BY c.id, c.lead_score, c.status;
END;
$$ LANGUAGE plpgsql;


-- FUNCTION 6: carga de trabalho de um vendedor
-- Uso:
--   SELECT * FROM fn_seller_workload(1);
CREATE OR REPLACE FUNCTION fn_seller_workload(p_seller_id INTEGER)
RETURNS TABLE (
    leads_ativas       BIGINT,
    leads_qualificadas BIGINT,
    leads_handoff      BIGINT,
    leads_frias        BIGINT,
    score_medio        NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM(CASE WHEN c.status = 'active'    THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.status = 'qualified' THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.status = 'handoff'   THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.status = 'cold'      THEN 1 ELSE 0 END),
        ROUND(AVG(c.lead_score), 2)
    FROM conversations c
    WHERE c.seller_id = p_seller_id;
END;
$$ LANGUAGE plpgsql;
