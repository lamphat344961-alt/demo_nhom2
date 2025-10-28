import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLarge,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.chatBubbleAI,
            borderRadius: BorderRadius.circular(
              AppConstants.messageBorderRadius,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.typingIndicator,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.chatBubbleUser
              : message.isError
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.chatBubbleAI,
          borderRadius: BorderRadius.circular(AppConstants.messageBorderRadius),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : message.isError
                ? AppTheme.errorColor
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
