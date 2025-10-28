import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[100],
    );
  }

  static const Color primaryColor = Colors.blue;
  static const Color chatBubbleUser = Colors.blue;
  static final Color chatBubbleAI = Colors.grey[300]!;
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.red;
}
