import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/semantic_colors.dart';
import '../../core/backends/backend_profile.dart';
import '../../core/backends/backends_providers.dart';
import '../../shared/l10n.dart';
import 'backend_form.dart';

/// First-run page shown while no backend is saved.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final emphasized = M3ETheme.of(context).typography.emphasized;
    final backends = ref.read(backendsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _BrandMark()),
                  const SizedBox(height: 28),
                  Text(
                    l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: emphasized.headlineLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  M3ECard(
                    variant: M3ECardVariant.filled,
                    color: theme.colorScheme.card,
                    borderRadius: BorderRadius.circular(28),
                    padding: const EdgeInsets.all(20),
                    child: BackendForm(
                      submitLabel: l10n.welcomeConnect,
                      onSubmit: (profile) =>
                          backends.save(profile, activate: true),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: M3EButton.text(
                        onPressed: () => backends.save(
                          BackendProfile.mock(name: l10n.backendMockName),
                          activate: true,
                        ),
                        child: Text(l10n.welcomeUseMock),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app glyph in a Material shape, popping in once on arrival.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = M3EShapeContainer(
      kind: M3EShapeKind.cookie9Sided,
      width: 96,
      height: 96,
      color: scheme.primaryContainer,
      child: Icon(
        Icons.hub_rounded,
        size: 44,
        color: scheme.onPrimaryContainer,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return mark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: mark,
    );
  }
}
