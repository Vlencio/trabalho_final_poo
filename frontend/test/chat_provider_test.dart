import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/models/message.dart';
import 'package:frontend/features/chat/providers/chat_provider.dart';
import 'package:frontend/features/chat/services/chat_api_service.dart';

void main() {
  test('ChatProvider sends messages through real API service contract', () async {
    final api = _FakeChatApi();
    final provider = ChatProvider(chatApi: api);

    await provider.sendMessage('  Quero uma moto  ');

    expect(api.sentTexts, ['Quero uma moto']);
    expect(provider.messages.length, 3);
    expect(provider.messages[1].id, 'backend-user-1');
    expect(provider.messages[1].isUser, isTrue);
    expect(provider.messages[2].content, 'Qual modelo voce procura?');
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('ChatProvider reports API errors in the chat', () async {
    final provider = ChatProvider(chatApi: _FailingChatApi());

    await provider.sendMessage('Olá');

    expect(provider.errorMessage, contains('Servidor indisponível'));
    expect(provider.messages.last.content, contains('Erro:'));
    expect(provider.isLoading, isFalse);
  });
}

class _FakeChatApi implements ChatApi {
  final sentTexts = <String>[];
  String _baseUrl = 'http://localhost:8000';

  @override
  String get baseUrl => _baseUrl;

  @override
  set baseUrl(String url) {
    _baseUrl = url;
  }

  @override
  Future<ChatExchange> sendMessage(String text) async {
    sentTexts.add(text);
    return ChatExchange(
      userMessage: Message(
        id: 'backend-user-1',
        content: text,
        isUser: true,
        timestamp: DateTime.parse('2026-05-25T10:00:00'),
      ),
      botMessage: Message(
        id: 'backend-bot-1',
        content: 'Qual modelo voce procura?',
        isUser: false,
        timestamp: DateTime.parse('2026-05-25T10:00:01'),
      ),
    );
  }
}

class _FailingChatApi implements ChatApi {
  @override
  String baseUrl = 'http://localhost:8000';

  @override
  Future<ChatExchange> sendMessage(String text) {
    throw Exception('Servidor indisponível');
  }
}
