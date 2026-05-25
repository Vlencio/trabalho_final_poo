-- ============================================================
-- Trabalho Final - Banco de Dados I
-- Sistema: Atendimento via WhatsApp (Concessionaria de Motos)
-- 8 entidades (1 fraca), normalizado ate a 3FN
-- ============================================================


-- ============================================================
-- ENTIDADES FORTES
-- ============================================================

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    wa_id           VARCHAR(50) NOT NULL UNIQUE,
    nome            VARCHAR(100),
    telefone        VARCHAR(20),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE sellers (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE motorcycle_models (
    id              SERIAL PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL UNIQUE,
    categoria       VARCHAR(30) NOT NULL,
    preco_base      NUMERIC(10, 2) NOT NULL,
    disponivel      BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_categoria CHECK (categoria IN ('street', 'trail', 'scooter', 'cargo', 'naked', 'esportiva')),
    CONSTRAINT chk_preco     CHECK (preco_base > 0)
);


CREATE TABLE conversations (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    seller_id       INTEGER,
    model_id        INTEGER,
    status          VARCHAR(20) NOT NULL DEFAULT 'active',
    lead_score      INTEGER,
    started_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at        TIMESTAMP,
    CONSTRAINT fk_conv_user   FOREIGN KEY (user_id)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_conv_seller FOREIGN KEY (seller_id) REFERENCES sellers(id),
    CONSTRAINT fk_conv_model  FOREIGN KEY (model_id)  REFERENCES motorcycle_models(id),
    CONSTRAINT chk_status     CHECK (status IN ('active', 'qualified', 'cold', 'opted_out', 'handoff')),
    CONSTRAINT chk_lead_score CHECK (lead_score IS NULL OR (lead_score >= 0 AND lead_score <= 100))
);


CREATE TABLE messages (
    id              SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    role            VARCHAR(15) NOT NULL,
    content         TEXT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msg_conv FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT chk_role    CHECK (role IN ('user', 'assistant', 'system'))
);


CREATE TABLE handoff_events (
    id              SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    seller_id       INTEGER,
    motivo          VARCHAR(30) NOT NULL,
    occurred_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_handoff_conv   FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT fk_handoff_seller FOREIGN KEY (seller_id)       REFERENCES sellers(id),
    CONSTRAINT chk_motivo        CHECK (motivo IN ('lead_qualificado', 'solicitacao_humano', 'erro_bot', 'horario_comercial', 'reatribuicao'))
);


CREATE TABLE lead_score_history (
    id              SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    score_anterior  INTEGER,
    score_novo      INTEGER NOT NULL,
    changed_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_lsh_conv         FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT chk_score_anterior  CHECK (score_anterior IS NULL OR (score_anterior >= 0 AND score_anterior <= 100)),
    CONSTRAINT chk_score_novo      CHECK (score_novo >= 0 AND score_novo <= 100)
);


-- ============================================================
-- ENTIDADE FRACA
-- qualification_slots depende de conversations: nao existe sem ela
-- e usa conversation_id como parte da chave primaria composta.
-- ============================================================

CREATE TABLE qualification_slots (
    conversation_id INTEGER NOT NULL,
    slot_name       VARCHAR(30) NOT NULL,
    slot_value      VARCHAR(200) NOT NULL,
    captured_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id, slot_name),
    CONSTRAINT fk_slot_conv  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT chk_slot_name CHECK (slot_name IN ('modelo', 'cidade', 'forma_pagamento', 'prazo_compra', 'tem_cnh', 'faixa_renda'))
);
