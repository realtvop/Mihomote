import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Extends the macOS canvas behind the transparent native titlebar while
/// keeping interactive Flutter content below the window controls.
class MacosWindowChrome extends StatefulWidget {
  const MacosWindowChrome({super.key, required this.child});

  final Widget child;

  @override
  State<MacosWindowChrome> createState() => _MacosWindowChromeState();
}

class _MacosWindowChromeState extends State<MacosWindowChrome> {
  static const _channel = MethodChannel('app.mihomote/window_chrome');

  // Keep the first frame clear of the standard macOS titlebar while the
  // native window reports its exact content-layout inset.
  static const _fallbackTitlebarHeight = 28.0;

  late double _titlebarHeight = _isMacos ? _fallbackTitlebarHeight : 0;

  bool get _isMacos => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (!_isMacos) return;
    _channel.setMethodCallHandler(_handleNativeCall);
    unawaited(_loadTitlebarHeight());
  }

  @override
  void dispose() {
    if (_isMacos) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _loadTitlebarHeight() async {
    try {
      _updateTitlebarHeight(
        await _channel.invokeMethod<num>('getTitlebarHeight'),
      );
    } on MissingPluginException {
      // Widget tests and non-standard embedders keep the safe fallback.
    } on PlatformException {
      // A native window failure must not prevent the app from starting.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'titlebarHeightChanged') {
      _updateTitlebarHeight(call.arguments as num?);
    }
  }

  void _updateTitlebarHeight(num? value) {
    final height = value?.toDouble();
    if (height == null || !height.isFinite || height < 0 || !mounted) return;
    if (_titlebarHeight == height) return;
    setState(() => _titlebarHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMacos) return widget.child;
    final media = MediaQuery.of(context);
    final paddingTop = math.max(media.padding.top, _titlebarHeight);
    final viewPaddingTop = math.max(media.viewPadding.top, _titlebarHeight);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(top: paddingTop),
        viewPadding: media.viewPadding.copyWith(top: viewPaddingTop),
      ),
      child: widget.child,
    );
  }
}
