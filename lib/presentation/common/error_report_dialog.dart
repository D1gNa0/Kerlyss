import 'package:flutter/material.dart';

import '../../core/services/error_reporter.dart';
import '../../core/services/toast_service.dart';

/// "Report this problem?" dialog. Nothing is sent by the app: the button opens a
/// pre-filled GitHub issue in the browser and copies the full report to the clipboard.
Future<void> showErrorReportDialog(
  BuildContext context,
  ErrorReportDraft draft,
) async {
  final reporter = ErrorReporter.instance;
  final preview = await reporter.buildReport(draft);
  final askEnabled = await reporter.isAskEnabled();
  if (!context.mounted) return;

  final noteController = TextEditingController();
  var dontAskAgain = false; // auto prompts: "Don't ask me again"
  var askForErrors = askEnabled; // manual dialog: switch the automatic prompts on/off

  Future<void> savePreference() async {
    if (draft.manual) {
      if (askForErrors != askEnabled) await reporter.setAskEnabled(askForErrors);
    } else if (dontAskAgain) {
      await reporter.setAskEnabled(false);
    }
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.bug_report_rounded, color: Colors.amberAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                draft.manual ? 'Report a problem' : 'Something went wrong',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.userMessage, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text(
                  'Nothing is sent automatically. "Report on GitHub" opens a pre-filled issue in your browser '
                  '(a free GitHub account is needed) and copies the full report to your clipboard. '
                  'Emails, IP addresses, user names and URL parameters are removed.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: draft.manual ? 'What happened? (optional)' : 'What were you doing? (optional)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(dialogContext).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('See exactly what will be shared', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white54,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            preview,
                            style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (draft.manual)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    value: askForErrors,
                    onChanged: (v) => setState(() => askForErrors = v ?? true),
                    title: const Text('Ask me to report serious errors', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  )
                else
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    value: dontAskAgain,
                    onChanged: (v) => setState(() => dontAskAgain = v ?? false),
                    title: const Text("Don't ask me about errors again", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await savePreference();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(draft.manual ? 'Close' : 'Not now', style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await reporter.copyReport(draft, note: noteController.text);
              if (context.mounted) ToastService.show(context, 'Report copied to clipboard');
            },
            child: const Text('Copy report'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await savePreference();
              final opened = await reporter.openIssue(draft, note: noteController.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ToastService.show(
                  context,
                  opened
                      ? 'Full report copied. Paste it into the issue if you want to add more.'
                      : 'Could not open the browser. The report was copied: paste it at github.com/D1gNa0/Kerlyss/issues',
                  duration: const Duration(seconds: 5),
                );
              }
            },
            child: const Text('Report on GitHub'),
          ),
        ],
      ),
    ),
  );

  // (controller intentionally not disposed: the dialog is still animating out)
}
