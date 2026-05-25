# Backend
# Atendente Virtual Shineray

Backend de um chatbot de atendimento via WhatsApp para uma concessionária de motos. O bot qualifica leads coletando informações do cliente (modelo de interesse, cidade, forma de pagamento, etc.) e transfere automaticamente para um vendedor quando o score atinge 70 pontos.

## Stack

- **FastAPI** — API REST
- **PostgreSQL** — banco de dados
- **psycopg3** — driver async para Postgres
- **Claude Haiku** (Anthropic) — modelo de linguagem que gera as respostas e captura os slots via tool use
- **pydantic-settings** — configuração via `.env`

## Estrutura

```
trabalho_final_poo/backend/
├── config.py                  # configurações (lê o .env)
├── api/
│   ├── main.py                # app FastAPI + lifespan
│   ├── deps.py                # injeção de dependências
│   ├── schemas.py             # modelos de request/response
│   └── routes/
│       ├── users.py
│       ├── conversations.py
│       └── messages.py
├── bot/
│   └── responder.py           # lógica do chatbot + loop de tool use
└── db/
    ├── pool.py                # pool de conexões async
    ├── models.py              # modelos Pydantic das tabelas
    ├── init_db.py             # script de inicialização do banco
    └── repositories/
        ├── base.py            # classe base abstrata
        ├── user_repo.py
        ├── conversation_repo.py
        ├── message_repo.py
        ├── seller_repo.py
        ├── motorcycle_model_repo.py
        ├── qualification_slot_repo.py
        ├── handoff_event_repo.py
        └── lead_score_history_repo.py
```

## Setup

**1. Crie o ambiente virtual e instale as dependências:**

```bash
cd trabalho_final_poo/backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**2. Crie o arquivo `.env` dentro de `backend/`:**

```env
POSTGRES_PASSWORD=sua_senha
ANTHROPIC_API_KEY=sk-ant-...
```

Variáveis opcionais (já têm default):

```env
POSTGRES_USER=postgres
POSTGRES_DB=atendente
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
HISTORY_MAX_MESSAGES=15
```

**3. Inicialize o banco:**

```bash
python -m db.init_db
```

Isso dropa o schema public, recria as tabelas, views, functions e triggers, e insere os vendedores e modelos de moto.

## Rodando a API

```bash
cd trabalho_final_poo/backend
source venv/bin/activate
uvicorn api.main:app --reload
```

A documentação interativa fica disponível em `http://localhost:8000/docs`.

## Testando

O `test.py` na raiz do projeto simula uma conversa completa de qualificação de lead e verifica que a API responde corretamente em cada etapa.

```bash
# com a API rodando em outro terminal:
pip install httpx
python test.py
```

O script passa por 8 etapas:

1. **Health check** — verifica que a API está de pé
2. **Criar usuário** — cria um cliente com `wa_id` (identificador do WhatsApp)
3. **Obter conversa** — busca ou cria uma conversa ativa para o usuário
4. **Simular conversa** — envia 7 mensagens cobrindo todos os slots de qualificação
5. **Estado final** — verifica score, status e vendedor atribuído
6. **Métricas** — chama a function SQL `fn_conversation_metrics`
7. **Listar conversas** — lista todas as conversas no banco
8. **Histórico** — lista todas as mensagens da conversa

## Score e handoff

Cada slot preenchido vale **15 pontos**. Com 6 slots possíveis o máximo é 90 pontos. Ao atingir **70 pontos**, a conversa é promovida para `qualified`, o bot atribui o vendedor com menos conversas abertas e registra um `HandoffEvent`.

Os slots capturáveis são: `modelo`, `cidade`, `forma_pagamento`, `prazo_compra`, `tem_cnh`, `faixa_renda`.
