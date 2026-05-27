import '../../../core/network/api_client.dart';
import '../models/message.dart';

abstract class ChatApi {
  String get baseUrl;
  set baseUrl(String url);

  Future<ChatExchange> sendMessage(String text);
}

class ChatApiService implements ChatApi {
  final ApiClient _apiClient;
  final String waId;
  final String nome;

  int? _userId;
  int? _conversationId;

  ChatApiService({
    ApiClient? apiClient,
    this.waId = 'flutter-demo-user',
    this.nome = 'Cliente App',
  }) : _apiClient = apiClient ?? ApiClient();

  @override
  String get baseUrl => _apiClient.baseUrl;

  @override
  set baseUrl(String url) {
    _apiClient.baseUrl = url;
    _userId = null;
    _conversationId = null;
  }

  @override
  Future<ChatExchange> sendMessage(String text) async {
    final conversationId = await _ensureConversation();
    final response = await _apiClient.post(
      '/conversations/$conversationId/messages',
      {'content': text},
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Formato de resposta inválido recebido do backend.');
    }

    return ChatExchange.fromJson(response);
  }

  Future<int> _ensureConversation() async {
    if (_conversationId != null) {
      return _conversationId!;
    }

    final user = await _apiClient.post('/users', {
      'wa_id': waId,
      'nome': nome,
    });
    if (user is! Map<String, dynamic> || user['id'] == null) {
      throw ApiException('Resposta inválida ao criar usuário.');
    }
    _userId = user['id'] as int;

    final conversation = await _apiClient.post(
      '/conversations/by-user/$_userId',
      {},
    );
    if (conversation is! Map<String, dynamic> || conversation['id'] == null) {
      throw ApiException('Resposta inválida ao criar conversa.');
    }
    _conversationId = conversation['id'] as int;

    return _conversationId!;
  }
}

class ChatExchange {
  final Message userMessage;
  final Message botMessage;

  ChatExchange({
    required this.userMessage,
    required this.botMessage,
  });

  factory ChatExchange.fromJson(Map<String, dynamic> json) {
    final userMessage = json['user_message'];
    final botMessage = json['bot_message'];

    if (userMessage is! Map<String, dynamic> ||
        botMessage is! Map<String, dynamic>) {
      throw ApiException('Resposta do chat não contém as mensagens esperadas.');
    }

    return ChatExchange(
      userMessage: Message.fromJson(userMessage),
      botMessage: Message.fromJson(botMessage),
    );
  }
}
