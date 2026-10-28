// Enforces the hard rules from AGENTS.md §3.1 and §3.3 on everything in lib/.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) => !f.path.contains(
          '${Platform.pathSeparator}gen${Platform.pathSeparator}',
        ),
      )
      .toList();

  const forbidden = {
    'package:flutter/material.dart':
        'use package:material_ui/material_ui.dart (AGENTS.md §3.1)',
    'package:flutter/cupertino.dart':
        'use cupertino_ui if Cupertino is needed (AGENTS.md §3.1)',
    'dart:io': 'breaks web/WASM builds (AGENTS.md §3.3)',
    'dart:html': 'breaks WASM builds (AGENTS.md §3.3)',
    'dart:js': 'breaks WASM builds (AGENTS.md §3.3)',
    'dart:js_util': 'breaks WASM builds (AGENTS.md §3.3)',
  };

  test('lib/ has sources to check', () => expect(sources, isNotEmpty));

  for (final MapEntry(key: library, value: reason) in forbidden.entries) {
    test('no import of $library in lib/', () {
      final pattern = RegExp(
        '''^\\s*(import|export)\\s+['"]${RegExp.escape(library)}['"]''',
        multiLine: true,
      );
      final offenders = [
        for (final file in sources)
          if (pattern.hasMatch(file.readAsStringSync())) file.path,
      ];
      expect(offenders, isEmpty, reason: reason);
    });
  }

  test('core/mihomo stays free of Flutter UI and Riverpod', () {
    final pattern = RegExp(
      r'''^\s*import\s+['"]package:(material_ui|material_3_expressive|flutter_riverpod|flutter/widgets\.dart)''',
      multiLine: true,
    );
    final offenders = [
      for (final file in sources)
        if (file.path.contains('core${Platform.pathSeparator}mihomo') &&
            pattern.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty, reason: 'see AGENTS.md §5.1');
  });
}
