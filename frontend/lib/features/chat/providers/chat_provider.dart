import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatApi _chatApi;
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _useMockMode;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get useMockMode => _useMockMode;
  String get baseUrl => _chatApi.baseUrl;

  ChatProvider({
    ChatApi? chatApi,
    bool useMockMode = false,
  })  : _chatApi = chatApi ?? ChatApiService(),
        _useMockMode = useMockMode {
    _messages.add(
      Message(
        id: 'initial_greet',
        content: 'Olá! Sou a Maria, atendente virtual da Shineray. Como posso ajudar você hoje?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void toggleMockMode(bool value) {
    _useMockMode = value;
    notifyListeners();
  }

  void updateBaseUrl(String newUrl) {
    _chatApi.baseUrl = newUrl;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _messages.add(
      Message(
        id: 'initial_greet_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Conversa reiniciada. Como posso ajudar você?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final optimisticUserMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(optimisticUserMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockMode) {
        // Simulate a slight network and generation delay for premium feel
        await Future.delayed(const Duration(milliseconds: 1500));
        
        final mockResponses = [
          'Interessante! Isso é algo que posso ajudar a analisar.',
          'Entendi perfeitamente. Com base nas melhores práticas de POO, estruturar as classes separando as responsabilidades é essencial.',
          'De acordo com o seu backend FastAPI, podemos modelar as requisições facilmente.',
          'Estou à disposição para responder qualquer dúvida sobre este projeto acadêmico ou sistema!',
        ];
        
        // Pick response based on message count or index
        final replyText = mockResponses[_messages.length % mockResponses.length];
        
        final aiMessage = Message(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          content: replyText,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMessage);
      } else {
        final exchange = await _chatApi.sendMessage(text.trim());
        final index = _messages.indexWhere((m) => m.id == optimisticUserMessage.id);
        if (index >= 0) {
          _messages[index] = exchange.userMessage;
        }
        _messages.add(exchange.botMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      
      // Append a system warning message to the chat
      _messages.add(
        Message(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          content: 'Erro: Não foi possível obter resposta do assistente. Verifique se o backend está rodando.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
