import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/widgets/status_views.dart';
import 'proxies_providers.dart';

/// Makes Command-R and Control-R force-refresh all proxy data below it.
class ProxyRefreshShortcutScope extends ConsumerWidget {
  const ProxyRefreshShortcutScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void refresh() {
      unawaited(_refresh(ref, FocusManager.instance.primaryFocus?.context));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): refresh,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): refresh,
      },
      child: child,
    );
  }

  Future<void> _refresh(WidgetRef ref, BuildContext? errorContext) async {
    try {
      await ref.read(proxyRefreshProvider.notifier).refresh();
    } catch (error, stackTrace) {
      if (errorContext != null && errorContext.mounted) {
        showErrorSnackbar(errorContext, error);
      } else {
        debugPrint('Proxy refresh failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}
