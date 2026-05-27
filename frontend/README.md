# Frontend - Atendente IA Shineray

Aplicativo Flutter do chat de atendimento virtual integrado ao backend FastAPI do projeto.

## Stack

- Flutter
- Provider para estado da tela de chat
- HTTP para consumir a API
- Material Design em tema escuro

## Requisitos

- Flutter SDK instalado e disponível no PATH
- Backend rodando em `http://localhost:8000`

Verifique a instalação:

```bash
flutter --version
```

## Instalação

Na raiz do projeto:

```bash
cd frontend
flutter pub get
```

## Rodando o app

Com o backend já iniciado:

```bash
cd frontend
flutter run
```

Para rodar no navegador:

```bash
flutter run -d chrome
```

Para listar dispositivos disponíveis:

```bash
flutter devices
```

## URL do backend

O app usa estes defaults:

- Web, macOS, iOS e desktop: `http://localhost:8000`
- Android Emulator: `http://10.0.2.2:8000`

Também é possível alterar a URL dentro do app:

1. Abra a tela de configurações pelo ícone de engrenagem.
2. Edite o campo "Endereço do Servidor".
3. Salve as alterações.

## Integração com a API

O fluxo real do chat é:

1. Criar ou recuperar usuário:

```http
POST /users
```

Body:

```json
{
  "wa_id": "flutter-demo-user",
  "nome": "Cliente App"
}
```

2. Criar ou recuperar conversa ativa:

```http
POST /conversations/by-user/{user_id}
```

3. Enviar mensagem:

```http
POST /conversations/{conversation_id}/messages
```

Body:

```json
{
  "content": "Tenho interesse em uma moto"
}
```

Resposta esperada:

```json
{
  "user_message": {
    "id": 1,
    "conversation_id": 10,
    "role": "user",
    "content": "Tenho interesse em uma moto",
    "created_at": "2026-05-25T10:00:00"
  },
  "bot_message": {
    "id": 2,
    "conversation_id": 10,
    "role": "assistant",
    "content": "Oi! Qual modelo voce procura?",
    "created_at": "2026-05-25T10:00:01"
  },
  "conversation": {
    "id": 10,
    "user_id": 1,
    "status": "active",
    "lead_score": 0,
    "seller_id": null,
    "model_id": null,
    "started_at": "2026-05-25T10:00:00",
    "last_message_at": "2026-05-25T10:00:01"
  }
}
```

## Modo mock

A tela de configurações possui o "Modo Mock (Simulado)".

- Ligado: o app responde localmente, sem chamar backend.
- Desligado: o app chama a API FastAPI real.

Por padrão, o app inicia integrado à API real.

## Testes

Rode os testes do frontend com:

```bash
cd frontend
flutter test
```

Os testes cobrem:

- Parse do modelo `Message`
- Serviço de integração com a API
- Provider do chat
- Smoke test da tela principal

## Estrutura principal

```text
lib/
├── core/
│   ├── network/api_client.dart
│   └── theme/
├── features/
│   ├── chat/
│   │   ├── models/message.dart
│   │   ├── providers/chat_provider.dart
│   │   ├── services/chat_api_service.dart
│   │   ├── views/chat_screen.dart
│   │   └── widgets/
│   └── settings/
└── main.dart
```

## Problemas comuns

Se aparecer erro de conexão:

- Confirme se o backend está rodando em `http://localhost:8000`.
- Abra `http://localhost:8000/health` no navegador.
- No Android Emulator, use `http://10.0.2.2:8000`.
- Confira a URL salva na tela de configurações.

Se `flutter` não for reconhecido:

```bash
export PATH="$PATH:/caminho/para/flutter/bin"
```
