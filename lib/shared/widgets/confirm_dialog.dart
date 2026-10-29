import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';

/// Asks [title] with cancel and [confirmLabel] buttons. Resolves true only
/// when confirmed; dismissing the dialog counts as cancel.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
}) async {
  final cancelLabel = context.l10n.actionCancel;
  final confirmed = await M3EDialog.show<bool>(
    context,
    dialog: Builder(
      builder: (dialogContext) => M3EDialog(
        title: title,
        content: message == null ? null : Text(message),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}
