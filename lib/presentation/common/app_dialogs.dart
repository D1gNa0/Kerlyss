import 'package:flutter/material.dart';
import '../theme/aether_colors.dart';

class AppDialogs {
  static Future<String?> promptText(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String cancelLabel = 'CANCEL',
    String? initialValue,
    String hintText = '',
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AetherColors.primaryAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelLabel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: Text(confirmLabel, style: const TextStyle(color: AetherColors.primaryAccent)),
          ),
        ],
      ),
    );

    return result;
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String cancelLabel = 'CANCEL',
    Color confirmColor = Colors.redAccent,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AetherColors.ultraDarkGray,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
