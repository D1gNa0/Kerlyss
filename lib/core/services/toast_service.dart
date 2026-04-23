import 'package:flutter/material.dart';

class ToastService {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 112),
          dismissDirection: DismissDirection.horizontal,
          duration: duration,
          backgroundColor: backgroundColor ?? Colors.white10,
        ),
      );
  }
}
