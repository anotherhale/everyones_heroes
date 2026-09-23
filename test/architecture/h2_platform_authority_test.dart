import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture regression checks for H.2 + J.1 platform authority.
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
      expect(
        source.contains('DeterministicExperienceSelectionService'),
        isFalse,
        reason: file.path,
      );
      expect(
        source.contains('AdaptiveExperienceComposer'),
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

  test('platform Today path does not invoke local selector', () {
    final platformUseCase = File(
      'lib/features/life_journey/application/use_cases/'
      'platform_get_today_experience_use_case.dart',
    );
    final source = platformUseCase.readAsStringSync();
    // Ban imports / construction, not explanatory comments.
    expect(
      source.contains(
        "import 'package:everyonesheroes/features/life_journey/application/"
        "services/deterministic_experience_selection_service.dart'",
      ),
      isFalse,
    );
    expect(
      source.contains(
        "import 'package:everyonesheroes/features/life_journey/application/"
        "services/adaptive_experience_composer.dart'",
      ),
      isFalse,
    );
    expect(source.contains('JourneyRepository'), isFalse);
    expect(source.contains('selectFor('), isFalse);
    expect(source.contains('compose('), isFalse);
  });

  test('getTodayExperience provider prefers platform client when configured', () {
    final provider = File(
      'lib/features/life_journey/application/providers/use_cases/'
      'get_today_experience_use_case_provider.dart',
    );
    final source = provider.readAsStringSync();
    expect(source.contains('PlatformGetTodayExperienceUseCase'), isTrue);
    expect(source.contains('ehPlatformClientProvider'), isTrue);
    expect(source.contains('usePlatformAuthority') ||
        source.contains('ehPlatformClientProvider'), isTrue);
  });
}
