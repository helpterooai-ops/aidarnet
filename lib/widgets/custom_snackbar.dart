import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration,
      elevation: 6,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, icon: Icons.check_circle_rounded, backgroundColor: const Color(0xFF10B981));
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, icon: Icons.error_rounded, backgroundColor: const Color(0xFFEF4444));
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, icon: Icons.warning_rounded, backgroundColor: const Color(0xFFF59E0B));
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, icon: Icons.info_rounded, backgroundColor: const Color(0xFF2563EB));
  }
}
