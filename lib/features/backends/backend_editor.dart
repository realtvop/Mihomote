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

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final form = BackendForm(
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
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: M3EAppBar.top(
              titleText: title,
              leading: M3EIconButton(
                icon: const Icon(Icons.close_rounded),
                variant: M3EIconButtonVariant.standard,
                tooltip: l10n.actionClose,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: form,
            ),
          ),
        );
      }
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(dialogContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                form,
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Asks before deleting a backend.
Future<void> confirmDeleteBackend(
  BuildContext context,
  WidgetRef ref,
  BackendProfile profile,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.backendDeleteConfirm(profile.name)),
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
  );
  if (confirmed == true) {
    await ref.read(backendsProvider.notifier).remove(profile.id);
  }
}
