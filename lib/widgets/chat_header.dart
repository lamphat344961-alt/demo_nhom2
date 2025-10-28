import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'ai_selector.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  final String selectedAI;
  final Function(String) onAIChanged;
  final bool isSpeaking;
  final VoidCallback onToggleTTS;

  const ChatHeader({
    super.key,
    required this.onClose,
    required this.selectedAI,
    required this.onAIChanged,
    required this.isSpeaking,
    required this.onToggleTTS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.borderRadius),
          topRight: Radius.circular(AppConstants.borderRadius),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.chat, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              const Expanded(
                child: Text(
                  AppConstants.chatTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // TTS Toggle Button
              IconButton(
                icon: Icon(
                  isSpeaking ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: onToggleTTS,
                tooltip: isSpeaking ? 'Tắt đọc' : 'Bật đọc',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AISelector(selectedAI: selectedAI, onChanged: onAIChanged),
        ],
      ),
    );
  }
}
