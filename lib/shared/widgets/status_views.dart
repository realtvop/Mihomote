import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/mihomo/mihomo_exception.dart';
import '../l10n.dart';

/// Localized, user-facing text for any error thrown by the data layer.
String describeError(AppLocalizations l10n, Object error) {
  if (error is! MihomoException) return l10n.errorUnknown;
  return switch (error.kind) {
    MihomoErrorKind.network => l10n.errorNetwork,
    MihomoErrorKind.unauthorized => l10n.errorUnauthorized,
    MihomoErrorKind.notFound => l10n.errorNotFound,
    MihomoErrorKind.timeout => l10n.errorTimeout,
    MihomoErrorKind.server => l10n.errorServer(error.message ?? ''),
    MihomoErrorKind.unknown => l10n.errorUnknown,
  };
}

/// Shows a short snackbar for a failed action.
void showErrorSnackbar(BuildContext context, Object error) {
  M3ESnackbar.show(context, message: describeError(context.l10n, error));
}

/// A big expressive shape with an icon, used for empty and error states.
class ShapeBadge extends StatelessWidget {
  const ShapeBadge({
    super.key,
    required this.icon,
    required this.kind,
    this.size = 96,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final M3EShapeKind kind;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return M3EShapeContainer(
      kind: kind,
      width: size,
      height: size,
      color: color ?? scheme.secondaryContainer,
      child: Center(
        child: Icon(
          icon,
          size: size * 0.42,
          color: iconColor ?? scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.badge, required this.message, this.action});

  final Widget badge;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StatusView(
    badge: ShapeBadge(icon: icon, kind: M3EShapeKind.cookie9Sided),
    message: message,
    action: action,
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StatusView(
      badge: ShapeBadge(
        icon: Icons.cloud_off_rounded,
        kind: M3EShapeKind.softBurst,
        color: scheme.errorContainer,
        iconColor: scheme.onErrorContainer,
      ),
      message: describeError(context.l10n, error),
      action: onRetry == null
          ? null
          : M3EButton.tonal(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.actionRetry),
            ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: M3ELoadingIndicator());
}

/// Renders an [AsyncValue]: loading indicator, error with retry, or [data].
/// Keeps showing previous data while refreshing.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
    );
  }
}
