import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);
    final isError = message.content.startsWith('Erro: ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser
                    ? null
                    : isError
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: !isUser
                    ? Border.all(
                        color: isError
                            ? AppColors.error.withOpacity(0.3)
                            : AppColors.border,
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : isError
                          ? AppColors.error
                          : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 8,
                right: isUser ? 8 : 0,
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
