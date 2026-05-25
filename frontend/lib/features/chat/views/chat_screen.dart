import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../../settings/views/settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Atendente IA'),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.useMockMode 
                      ? AppColors.secondary.withOpacity(0.15) 
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.useMockMode 
                        ? AppColors.secondary.withOpacity(0.4) 
                        : AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  provider.useMockMode ? 'Mock' : 'API',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: provider.useMockMode ? AppColors.accent : AppColors.primary,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Limpar Conversa',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpar histórico?'),
                  content: const Text('Esta ação irá apagar todas as mensagens da conversa atual.'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Confirmar', style: TextStyle(color: AppColors.error)),
                      onPressed: () {
                        context.read<ChatProvider>().clearChat();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          // Trigger scroll to bottom whenever messages list length changes
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return Column(
            children: [
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(
                            message: chatProvider.messages[index],
                          );
                        },
                      ),
              ),
              if (chatProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Assistente digitando...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ChatInput(
                onSend: (text) => chatProvider.sendMessage(text),
                isLoading: chatProvider.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}
