import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backends/backend_profile.dart';
import '../../core/backends/backends_providers.dart';
import '../../core/state/core_providers.dart';
import '../../shared/l10n.dart';
import '../theme/semantic_colors.dart';
import 'shell_scope.dart';

/// Shows the active backend and switches between saved ones.
///
/// Renders as a compact avatar when narrow (top bar, collapsed rail) and as a
/// labeled card when there's room (expanded rail).
class BackendSwitcher extends ConsumerWidget {
  const BackendSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backendsProvider);
    final active = state.active;
    if (active == null) return const SizedBox.shrink();
    final l10n = context.l10n;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final profile in state.profiles)
          MenuItemButton(
            leadingIcon: Icon(
              profile.id == active.id
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 20,
            ),
            onPressed: () =>
                ref.read(backendsProvider.notifier).activate(profile.id),
            child: _ProfileLabel(profile: profile),
          ),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const Icon(Icons.tune_rounded, size: 20),
          onPressed: ShellScope.maybeOf(context)?.openSettings,
          child: Text(l10n.backendManage),
        ),
      ],
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        return LayoutBuilder(
          builder: (context, constraints) {
            // App bar actions lay out with unbounded width; only go wide
            // when a parent (the expanded rail) actually offers room.
            final wide =
                constraints.hasBoundedWidth && constraints.maxWidth >= 160;
            return Tooltip(
              message: l10n.backendSwitcherTooltip,
              child: wide
                  ? _WideTrigger(profile: active, onTap: toggle)
                  : _BackendAvatar(profile: active, onTap: toggle),
            );
          },
        );
      },
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  const _ProfileLabel({required this.profile});

  final BackendProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          profile.isMock
              ? context.l10n.backendMockDescription
              : profile.displayAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Initial inside an expressive shape, with a dot for connection health.
class _BackendAvatar extends ConsumerWidget {
  const _BackendAvatar({required this.profile, this.onTap});

  final BackendProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final health = ref.watch(versionProvider);
    final dotColor = switch (health) {
      AsyncData() => scheme.success,
      AsyncError() => scheme.error,
      _ => scheme.outline,
    };
    final initial = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().characters.first.toUpperCase();

    return Semantics(
      button: true,
      label: profile.name,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              M3EShapeContainer(
                kind: M3EShapeKind.cookie4Sided,
                width: 36,
                height: 36,
                color: scheme.tertiaryContainer,
                child: Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideTrigger extends StatelessWidget {
  const _WideTrigger({required this.profile, required this.onTap});

  final BackendProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              _BackendAvatar(profile: profile),
              const SizedBox(width: 4),
              Expanded(child: _ProfileLabel(profile: profile)),
              Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
