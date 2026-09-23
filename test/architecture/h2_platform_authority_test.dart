import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lightweight dependency-direction checks for H.2 authority migration.
void main() {
  test('presentation does not import pattern detector implementations', () {
    final presentation = Directory('lib/features/life_journey/presentation');
    final files = presentation
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        source.contains('rule_based_pattern_detector.dart'),
        isFalse,
        reason: file.path,
      );
      expect(
        source.contains('DetectPatternUseCase'),
        isFalse,
        reason: file.path,
      );
      expect(
        source.contains('BehaviorPatternsDetected('),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('platform client does not import postgres', () {
    final client = File(
      'lib/features/life_journey/infrastructure/platform/eh_platform_client.dart',
    );
    expect(client.readAsStringSync().contains('package:postgres'), isFalse);
  });
}
