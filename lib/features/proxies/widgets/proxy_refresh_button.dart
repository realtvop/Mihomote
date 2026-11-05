import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/l10n.dart';
import '../../../shared/widgets/status_views.dart';
import '../proxies_providers.dart';

/// Forces both proxy groups and providers to refresh.
class ProxyRefreshButton extends ConsumerWidget {
  const ProxyRefreshButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(proxyRefreshProvider);
    return M3EIconButton(
      icon: refreshing
          ? const M3ELoadingIndicator(size: 24)
          : const Icon(Icons.refresh_rounded),
      variant: M3EIconButtonVariant.standard,
      tooltip: context.l10n.proxiesRefreshAll,
      onPressed: refreshing ? null : () => unawaited(_refresh(context, ref)),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(proxyRefreshProvider.notifier).refresh();
    } catch (error) {
      if (context.mounted) showErrorSnackbar(context, error);
    }
  }
}
