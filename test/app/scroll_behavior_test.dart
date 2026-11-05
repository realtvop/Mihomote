import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mihomote/app/scroll_behavior.dart';
import 'package:mihomote/app/theme/app_theme.dart';

void main() {
  testWidgets('mouse cannot drag scroll, including through refresh indicator', (
    tester,
  ) async {
    final theme = AppTheme.fromSeed(Colors.blue);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const MihomoteScrollBehavior(),
        theme: theme.lightMaterial,
        home: M3EResolvedTheme(
          data: theme.light,
          child: Scaffold(
            body: M3ERefreshIndicator(
              onRefresh: () async => refreshCount++,
              child: ListView.builder(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 50,
                itemBuilder: (context, index) =>
                    SizedBox(height: 60, child: Text('Item $index')),
              ),
            ),
          ),
        ),
      ),
    );

    final listContext = tester.element(find.byType(ListView));
    final behavior = ScrollConfiguration.of(listContext);
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    expect(behavior.dragDevices, isNot(contains(PointerDeviceKind.mouse)));

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -300),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(controller.offset, 0);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, 300),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(refreshCount, 0);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -300),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    expect(controller.offset, greaterThan(0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
