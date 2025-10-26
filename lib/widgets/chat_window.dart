import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import 'chat_header.dart';
import 'chat_input.dart';
import 'chat_bubble.dart';

class ChatWindow extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onClose;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onToggleTTS;
  final bool isLoading;
  final bool isListening;
  final bool isSpeaking;
  final String selectedAI;
  final Function(String) onAIChanged;
  final ScrollController? scrollController;

  const ChatWindow({
    super.key,
    required this.messages,
    required this.controller,
    required this.onClose,
    required this.onSend,
    required this.onMicPressed,
    required this.onToggleTTS,
    this.isLoading = false,
    this.isListening = false,
    this.isSpeaking = false,
    required this.selectedAI,
    required this.onAIChanged,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.chatWindowWidth,
      height: AppConstants.chatWindowHeight,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          ChatHeader(
            onClose: onClose,
            selectedAI: selectedAI,
            onAIChanged: onAIChanged,
            isSpeaking: isSpeaking,
            onToggleTTS: onToggleTTS,
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      AppConstants.startConversation,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    physics: const ClampingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: messages[index]);
                    },
                  ),
          ),
          ChatInput(
            controller: controller,
            onSend: onSend,
            onMicPressed: onMicPressed,
            isLoading: isLoading,
            isListening: isListening,
          ),
        ],
      ),
    );
  }
}
