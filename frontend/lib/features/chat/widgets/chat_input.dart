import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.isLoading,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus(); // Re-focus after sending for better desktop UX
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSubmit(),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: widget.isLoading 
                      ? 'Assistente pensando...' 
                      : 'Envie uma mensagem...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  fillColor: AppColors.surfaceElevated,
                  filled: true,
                ),
                enabled: !widget.isLoading,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSubmit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.isLoading ? null : AppColors.primaryGradient,
                  color: widget.isLoading ? AppColors.border : null,
                  shape: BoxShape.circle,
                  boxShadow: widget.isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
