import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/chat/services/chat_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ChatApiService creates user, creates conversation, and sends content', () async {
    final requestedPaths = <String>[];
    late Map<String, dynamic> sentMessageBody;

    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);

      if (request.url.path == '/users') {
        expect(jsonDecode(request.body), {
          'wa_id': 'wa-123',
          'nome': 'Cliente Teste',
        });
        return http.Response(
          jsonEncode({'id': 10, 'wa_id': 'wa-123', 'nome': 'Cliente Teste'}),
          200,
        );
      }

      if (request.url.path == '/conversations/by-user/10') {
        return http.Response(
          jsonEncode({
            'id': 99,
            'user_id': 10,
            'status': 'active',
            'lead_score': 0,
            'seller_id': null,
            'model_id': null,
            'started_at': '2026-05-25T10:00:00',
            'last_message_at': '2026-05-25T10:00:00',
          }),
          200,
        );
      }

      if (request.url.path == '/conversations/99/messages') {
        sentMessageBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'user_message': {
              'id': 1,
              'conversation_id': 99,
              'role': 'user',
              'content': 'Olá',
              'created_at': '2026-05-25T10:01:00',
            },
            'bot_message': {
              'id': 2,
              'conversation_id': 99,
              'role': 'assistant',
              'content': 'Oi! Qual modelo voce procura?',
              'created_at': '2026-05-25T10:01:01',
            },
            'conversation': {
              'id': 99,
              'user_id': 10,
              'status': 'active',
              'lead_score': 0,
              'seller_id': null,
              'model_id': null,
              'started_at': '2026-05-25T10:00:00',
              'last_message_at': '2026-05-25T10:01:01',
            },
          }),
          200,
        );
      }

      return http.Response('not found', 404);
    });

    final service = ChatApiService(
      apiClient: ApiClient(baseUrl: 'http://localhost:8000', httpClient: client),
      waId: 'wa-123',
      nome: 'Cliente Teste',
    );

    final exchange = await service.sendMessage('Olá');

    expect(requestedPaths, [
      '/users',
      '/conversations/by-user/10',
      '/conversations/99/messages',
    ]);
    expect(sentMessageBody, {'content': 'Olá'});
    expect(exchange.userMessage.isUser, isTrue);
    expect(exchange.botMessage.content, 'Oi! Qual modelo voce procura?');
  });

  test('ChatApiService reuses active conversation after first send', () async {
    var createConversationCalls = 0;
    var sendMessageCalls = 0;

    final client = MockClient((request) async {
      if (request.url.path == '/users') {
        return http.Response(jsonEncode({'id': 10}), 200);
      }
      if (request.url.path == '/conversations/by-user/10') {
        createConversationCalls++;
        return http.Response(jsonEncode({'id': 99}), 200);
      }
      if (request.url.path == '/conversations/99/messages') {
        sendMessageCalls++;
        return http.Response(
          jsonEncode({
            'user_message': {
              'id': sendMessageCalls * 2 - 1,
              'conversation_id': 99,
              'role': 'user',
              'content': 'Mensagem',
              'created_at': '2026-05-25T10:01:00',
            },
            'bot_message': {
              'id': sendMessageCalls * 2,
              'conversation_id': 99,
              'role': 'assistant',
              'content': 'Resposta',
              'created_at': '2026-05-25T10:01:01',
            },
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    final service = ChatApiService(
      apiClient: ApiClient(baseUrl: 'http://localhost:8000', httpClient: client),
    );

    await service.sendMessage('Primeira');
    await service.sendMessage('Segunda');

    expect(createConversationCalls, 1);
    expect(sendMessageCalls, 2);
  });
}
