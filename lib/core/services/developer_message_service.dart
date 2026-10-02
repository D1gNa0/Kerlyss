import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/logger_service.dart';
import '../../presentation/theme/aether_colors.dart';

class DeveloperMessageService {
  static const String _messageUrl =
      'https://raw.githubusercontent.com/D1gNa0/Kerlyss/main/developer_message.json';

  Future<File> _getDismissedFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/dismissed_developer_messages.json');
  }

  Future<Set<String>> _getDismissedIds() async {
    try {
      final file = await _getDismissedFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List?;
        if (list != null) {
          return list.cast<String>().toSet();
        }
      }
    } catch (e) {
      Log.w('DeveloperMessageService: Could not read dismissed IDs: $e');
    }
    return {};
  }

  Future<void> _saveDismissedId(String id) async {
    try {
      final dismissed = await _getDismissedIds();
      dismissed.add(id);
      final file = await _getDismissedFile();
      await file.writeAsString(jsonEncode(dismissed.toList()));
    } catch (e) {
      Log.w('DeveloperMessageService: Could not save dismissed ID: $e');
    }
  }

  Future<void> checkForMessages(BuildContext context) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)));
      final response = await dio.get(_messageUrl);

      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data is! Map<String, dynamic>) return;

        final showMessage = (data['showMessage'] as bool?) ?? false;
        if (!showMessage) return;

        final id = (data['id'] as String?) ?? 'default_msg';
        final dismissable = (data['dismissable'] as bool?) ?? true;

        if (dismissable) {
          final dismissedIds = await _getDismissedIds();
          if (dismissedIds.contains(id)) return;
        }

        final title = (data['title'] as String?) ?? 'Developer Message';
        final message = (data['message'] as String?) ?? '';
        final actionLabel = data['actionLabel'] as String?;
        final actionUrl = data['actionUrl'] as String?;
        final priority = (data['priority'] as String?) ?? 'info';

        if (context.mounted && message.isNotEmpty) {
          _showMessageDialog(
            context,
            id: id,
            title: title,
            message: message,
            actionLabel: actionLabel,
            actionUrl: actionUrl,
            dismissable: dismissable,
            priority: priority,
          );
        }
      }
    } catch (e) {
      // Non-critical network/parsing failures should fail silently
      Log.i('DeveloperMessageService: Message check skipped or unavailable: $e');
    }
  }

  void _showMessageDialog(
    BuildContext context, {
    required String id,
    required String title,
    required String message,
    String? actionLabel,
    String? actionUrl,
    required bool dismissable,
    required String priority,
  }) {
    Color accentColor;
    IconData icon;
    switch (priority.toLowerCase()) {
      case 'warning':
        accentColor = Colors.amberAccent;
        icon = Icons.warning_amber_rounded;
        break;
      case 'critical':
      case 'error':
        accentColor = AetherColors.error;
        icon = Icons.error_outline_rounded;
        break;
      case 'info':
      default:
        accentColor = AetherColors.accentCyan;
        icon = Icons.campaign_rounded;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: dismissable,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentColor.withValues(alpha: 0.25), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          if (actionUrl != null && actionUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                if (dismissable) {
                  _saveDismissedId(id);
                }
                Navigator.pop(dialogContext);
              },
              child: Text(
                dismissable ? 'Dismiss' : 'Close',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.2),
              foregroundColor: accentColor,
              elevation: 0,
              side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (actionUrl != null && actionUrl.isNotEmpty) {
                try {
                  final uri = Uri.parse(actionUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  Log.e('DeveloperMessageService: Could not launch URL: $e');
                }
              }
              if (dismissable) {
                _saveDismissedId(id);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(actionLabel?.isNotEmpty == true ? actionLabel! : 'OK'),
          ),
        ],
      ),
    );
  }
}
