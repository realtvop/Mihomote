import 'package:flutter/services.dart';

import '../../core/mihomo/mihomo_api.dart';

/// Native macOS status-item and window commands.
abstract final class MenuBarBridge {
  static const channel = MethodChannel('app.mihomote/menu_bar');

  static Future<void> configure({
    required String showTraffic,
    required String openMainWindow,
    required String quit,
  }) => _invoke('configure', {
    'showTraffic': showTraffic,
    'openMainWindow': openMainWindow,
    'quit': quit,
  });

  static Future<void> publishTraffic(TrafficSample sample) =>
      _invoke('updateTraffic', {'up': sample.up, 'down': sample.down});

  static Future<void> openMainWindow() => _invoke('openMainWindow');

  static Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // The menu-bar surface is macOS-only; widget tests and other platforms
      // intentionally have no native handler.
    }
  }
}
