import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

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
                  const Center(child: _HeroShapes()),
                  const SizedBox(height: 32),
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

/// A slowly turning cluster of Material shapes around the app glyph.
class _HeroShapes extends StatefulWidget {
  const _HeroShapes();

  @override
  State<_HeroShapes> createState() => _HeroShapesState();
}

class _HeroShapesState extends State<_HeroShapes>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            top: 10,
            child: M3EShapeContainer(
              kind: M3EShapeKind.pill,
              width: 64,
              height: 40,
              color: scheme.secondaryContainer,
            ),
          ),
          Positioned(
            right: 10,
            bottom: 4,
            child: M3EShapeContainer(
              kind: M3EShapeKind.cookie4Sided,
              width: 56,
              height: 56,
              color: scheme.tertiaryContainer,
            ),
          ),
          RotationTransition(
            turns: _spin,
            child: M3EShapeContainer(
              kind: M3EShapeKind.verySunny,
              width: 128,
              height: 128,
              color: scheme.primaryContainer,
            ),
          ),
          Icon(Icons.hub_rounded, size: 52, color: scheme.onPrimaryContainer),
        ],
      ),
    );
  }
}
