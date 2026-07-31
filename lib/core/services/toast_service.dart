import 'package:flutter/material.dart';
import 'dart:ui';
import '../../presentation/theme/aether_colors.dart';

class ToastService {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final bool isError = backgroundColor == Colors.redAccent || backgroundColor == AetherColors.error;
    final bool isWarning = backgroundColor == Colors.amber || backgroundColor == AetherColors.warning;

    final IconData leadingIcon = icon ??
        (isError
            ? Icons.error_outline_rounded
            : isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded);

    final Color accentColor = isError
        ? Colors.redAccent
        : isWarning
            ? Colors.amberAccent
            : AetherColors.accentCyan;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          dismissDirection: DismissDirection.horizontal,
          duration: duration,
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (backgroundColor ?? AetherColors.ultraDarkGray).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          leadingIcon,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}
