import 'package:flutter/material.dart';

class ChatButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onPressed;

  const ChatButton({super.key, required this.isOpen, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(isOpen ? Icons.close : Icons.chat),
    );
  }
}
