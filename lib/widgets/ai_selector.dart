import 'package:flutter/material.dart';

class AISelector extends StatelessWidget {
  final String selectedAI;
  final Function(String) onChanged;

  const AISelector({
    super.key,
    required this.selectedAI,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedAI,
            underline: const SizedBox(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'chatgpt', child: Text('ChatGPT')),
              DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
