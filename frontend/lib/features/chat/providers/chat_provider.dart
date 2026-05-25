import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _useMockMode = true; // Defaults to mock mode for easy testing out-of-the-box

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get useMockMode => _useMockMode;
  String get baseUrl => _apiClient.baseUrl;

  ChatProvider() {
    // Add an initial greeting message from the AI assistant
    _messages.add(
      Message(
        id: 'initial_greet',
        content: 'Olá! Sou seu assistente inteligente. Como posso ajudar você hoje?',
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
    _apiClient.baseUrl = newUrl;
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

    final userMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
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
        // Send request to real backend FastAPI
        // Endpoint structure matches common chatbot endpoints
        final response = await _apiClient.post('/chat', {
          'message': text,
        });

        if (response != null && response is Map<String, dynamic>) {
          final replyText = response['response'] ?? response['reply'] ?? 'Sem resposta do servidor.';
          final aiMessage = Message(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: replyText.toString(),
            isUser: false,
            timestamp: DateTime.now(),
          );
          _messages.add(aiMessage);
        } else {
          throw ApiException('Formato de resposta inválido recebido do backend.');
        }
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
