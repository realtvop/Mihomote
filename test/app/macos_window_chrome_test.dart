import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/macos_window_chrome.dart';

const _channel = MethodChannel('app.mihomote/window_chrome');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reserves the titlebar height reported by macOS', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          expect(call.method, 'getTitlebarHeight');
          return 36.0;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );

    EdgeInsets? padding;
    EdgeInsets? viewPadding;
    await tester.pumpWidget(
      MaterialApp(
        home: MacosWindowChrome(
          child: Builder(
            builder: (context) {
              padding = MediaQuery.paddingOf(context);
              viewPadding = MediaQuery.viewPaddingOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(padding?.top, 36);
    expect(viewPadding?.top, 36);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('keeps a safe first-frame fallback without the native channel', (
    tester,
  ) async {
    EdgeInsets? padding;
    await tester.pumpWidget(
      MaterialApp(
        home: MacosWindowChrome(
          child: Builder(
            builder: (context) {
              padding = MediaQuery.paddingOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(padding?.top, 28);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
