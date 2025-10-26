import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        AppConstants.emptyStateText,
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }
}
