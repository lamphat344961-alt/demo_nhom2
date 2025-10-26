import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final bool isLoading;
  final bool isListening;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMicPressed,
    this.isLoading = false,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.borderRadius),
          bottomRight: Radius.circular(AppConstants.borderRadius),
        ),
      ),
      child: Row(
        children: [
          // Microphone button
          Container(
            decoration: BoxDecoration(
              color: isListening ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
              onPressed: isLoading ? null : onMicPressed,
              tooltip: isListening ? 'Dừng ghi âm' : 'Nhấn để nói',
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),

          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading && !isListening,
              decoration: InputDecoration(
                hintText: isListening
                    ? 'Đang nghe...'
                    : AppConstants.chatPlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingSmall,
                ),
              ),
              onSubmitted: isLoading || isListening ? null : (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),

          // Send button
          FloatingActionButton(
            mini: true,
            onPressed: isLoading || isListening ? null : onSend,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
