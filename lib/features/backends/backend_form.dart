import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/semantic_colors.dart';
import '../../core/backends/backend_profile.dart';
import '../../core/backends/backends_providers.dart';
import '../../core/mihomo/controller_url.dart';
import '../../core/mihomo/mihomo_client.dart';
import '../../shared/l10n.dart';
import '../../shared/widgets/status_views.dart';

/// Name / address / secret form with an inline connection test.
class BackendForm extends StatefulWidget {
  const BackendForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  final BackendProfile? initial;
  final String submitLabel;
  final Future<void> Function(BackendProfile profile) onSubmit;

  @override
  State<BackendForm> createState() => _BackendFormState();
}

sealed class _TestResult {}

class _TestOk extends _TestResult {
  _TestOk(this.version);
  final String version;
}

class _TestFailed extends _TestResult {
  _TestFailed(this.error);
  final Object error;
}

class _BackendFormState extends State<BackendForm> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _url = TextEditingController(text: widget.initial?.url);
  late final _secret = TextEditingController(text: widget.initial?.secret);
  String? _urlError;
  _TestResult? _result;
  bool _testing = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _secret.dispose();
    super.dispose();
  }

  /// Validates input and builds a profile, or flags the address field.
  BackendProfile? _profile() {
    final uri = parseControllerUrl(_url.text);
    if (uri == null) {
      setState(() => _urlError = context.l10n.backendUrlInvalid);
      return null;
    }
    final name = _name.text.trim();
    return BackendProfile(
      id: widget.initial?.id ?? BackendsNotifier.newId(),
      name: name.isEmpty ? uri.host : name,
      url: uri.toString(),
      secret: _secret.text.trim(),
    );
  }

  Future<void> _test() async {
    final profile = _profile();
    if (profile == null) return;
    setState(() {
      _testing = true;
      _result = null;
    });
    final client = MihomoClient(baseUri: profile.uri!, secret: profile.secret);
    _TestResult result;
    try {
      result = _TestOk((await client.version()).version);
    } catch (e) {
      result = _TestFailed(e);
    } finally {
      client.close();
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _result = result;
      });
    }
  }

  Future<void> _submit() async {
    final profile = _profile();
    if (profile == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(profile);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          M3ETextField(
            controller: _name,
            label: l10n.backendNameLabel,
            placeholder: l10n.backendNameHint,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          M3ETextField(
            controller: _url,
            label: l10n.backendUrlLabel,
            supportingText: l10n.backendUrlSupporting,
            errorText: _urlError,
            isRequired: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_urlError != null || _result != null) {
                setState(() {
                  _urlError = null;
                  _result = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          M3ETextField(
            controller: _secret,
            label: l10n.backendSecretLabel,
            supportingText: l10n.backendSecretSupporting,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _result == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _TestResultBanner(result: _result!),
                  ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              M3EButton.tonal(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: M3ELoadingIndicator(size: 20),
                      )
                    : const Icon(Icons.network_check_rounded),
                label: Text(l10n.backendTest),
              ),
              M3EButton.filled(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestResultBanner extends StatelessWidget {
  const _TestResultBanner({required this.result});

  final _TestResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final (icon, color, text) = switch (result) {
      _TestOk(:final version) => (
        Icons.check_circle_rounded,
        scheme.success,
        l10n.backendTestSuccess(version),
      ),
      _TestFailed(:final error) => (
        Icons.error_rounded,
        scheme.error,
        describeError(l10n, error),
      ),
    };
    return M3ECard(
      variant: M3ECardVariant.filled,
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
