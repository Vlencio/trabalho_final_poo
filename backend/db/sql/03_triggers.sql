-- ============================================================
-- TRIGGERS DO PROJETO
-- 4 triggers que chamam functions definidas em 04_functions.sql
-- ============================================================


-- TRIGGER 1: atualiza updated_at quando o usuario e modificado
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- TRIGGER 2: atualiza last_message_at da conversa quando chega
-- uma nova mensagem
CREATE TRIGGER trg_msg_update_conv
AFTER INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION update_conv_last_message_at();


-- TRIGGER 3: auditoria automatica de mudancas de score
-- Insere uma linha em lead_score_history sempre que conversations.lead_score muda
CREATE TRIGGER trg_audit_lead_score
AFTER UPDATE ON conversations
FOR EACH ROW EXECUTE FUNCTION fn_audit_lead_score();


-- TRIGGER 4: bloqueio de mensagens em conversas com opt-out (LGPD)
CREATE TRIGGER trg_block_optout_messages
BEFORE INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION fn_block_optout_messages();
