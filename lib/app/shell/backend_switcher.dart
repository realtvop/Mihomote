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

    final notifier = ref.read(backendsProvider.notifier);
    final openSettings = ShellScope.maybeOf(context)?.openSettings;

    M3EMenu menu({
      required M3EMenuAnchorPosition position,
      required M3EMenuAnchorBuilder anchorBuilder,
    }) {
      return M3EMenu(
        position: position,
        selectedValue: active.id,
        anchorBuilder: anchorBuilder,
        children: [
          for (final profile in state.profiles)
            M3EMenuSelectable(
              label: profile.name,
              supportingText: profile.isMock
                  ? l10n.backendMockDescription
                  : profile.displayAddress,
              value: profile.id,
              selected: profile.id == active.id,
              onPressed: () => notifier.activate(profile.id),
            ),
          const M3EMenuDivider(),
          M3EMenuEntry(
            label: l10n.backendManage,
            leading: const Icon(Icons.tune_rounded),
            enabled: openSettings != null,
            onPressed: openSettings,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // App bar actions lay out with unbounded width; only go wide when a
        // parent (the expanded rail) actually offers room.
        final wide = constraints.hasBoundedWidth && constraints.maxWidth >= 160;
        if (wide) {
          return menu(
            position: M3EMenuAnchorPosition.bottomStart,
            anchorBuilder: (context, open) => M3ETooltip(
              message: l10n.backendSwitcherTooltip,
              child: _WideTrigger(profile: active, onTap: open),
            ),
          );
        }
        return menu(
          position: M3EMenuAnchorPosition.bottomEnd,
          anchorBuilder: (context, open) => M3EIconButton(
            icon: _BackendAvatar(
              profile: active,
              ringColor: Theme.of(context).colorScheme.canvas,
            ),
            variant: M3EIconButtonVariant.standard,
            tooltip: l10n.backendSwitcherTooltip,
            semanticLabel: active.name,
            onPressed: open,
          ),
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
/// Sized to sit inside a standard icon button.
class _BackendAvatar extends ConsumerWidget {
  const _BackendAvatar({required this.profile, required this.ringColor});

  final BackendProfile profile;

  /// The background behind the avatar, used to cut the health dot out.
  final Color ringColor;

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

    return SizedBox.square(
      dimension: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          M3EShapeContainer(
            kind: M3EShapeKind.cookie4Sided,
            width: 32,
            height: 32,
            color: scheme.primaryContainer,
            child: Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Kept inside the button's round face so it isn't clipped.
          Positioned(
            right: 5,
            bottom: 5,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2),
              ),
            ),
          ),
        ],
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
    return M3ECard(
      variant: M3ECardVariant.filled,
      color: scheme.card,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      semanticLabel: profile.name,
      onPressed: onTap,
      child: Row(
        children: [
          _BackendAvatar(profile: profile, ringColor: scheme.card),
          const SizedBox(width: 8),
          Expanded(child: _ProfileLabel(profile: profile)),
          Icon(
            Icons.unfold_more_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
