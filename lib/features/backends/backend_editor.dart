import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backends/backend_profile.dart';
import '../../core/backends/backends_providers.dart';
import '../../shared/l10n.dart';
import '../../shared/layout/window_size_class.dart';
import 'backend_form.dart';

/// Adds or edits a backend: full-screen on compact windows, a dialog
/// elsewhere. New backends become active right away.
Future<void> showBackendEditor(
  BuildContext context,
  WidgetRef ref, {
  BackendProfile? initial,
}) {
  final l10n = context.l10n;
  final title = initial == null ? l10n.backendAddTitle : l10n.backendEditTitle;
  final compact = WindowSizeClass.of(context).isCompact;

  // Built inside the dialog route so submitting can pop it.
  Widget form(BuildContext dialogContext) => BackendForm(
    initial: initial,
    submitLabel: l10n.actionSave,
    onSubmit: (profile) async {
      await ref
          .read(backendsProvider.notifier)
          .save(profile, activate: initial == null);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    },
  );

  if (compact) {
    return M3EDialog.showFullScreen<void>(
      context,
      title: title,
      body: Builder(builder: form),
    );
  }
  return M3EDialog.show<void>(
    context,
    dialog: Builder(
      builder: (dialogContext) =>
          M3EDialog(title: title, content: form(dialogContext)),
    ),
  );
}

/// Asks before deleting a backend.
Future<void> confirmDeleteBackend(
  BuildContext context,
  WidgetRef ref,
  BackendProfile profile,
) async {
  final l10n = context.l10n;
  final confirmed = await M3EDialog.show<bool>(
    context,
    dialog: Builder(
      builder: (dialogContext) => M3EDialog(
        title: l10n.backendDeleteConfirm(profile.name),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    ),
  );
  if (confirmed == true) {
    await ref.read(backendsProvider.notifier).remove(profile.id);
  }
}
