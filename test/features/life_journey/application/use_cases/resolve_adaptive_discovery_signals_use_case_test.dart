import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/discovery/discovery_profile_fixture.dart';
import '../../builders/behavioral_evidence_builder.dart';

void main() {
  late InMemoryReflectionRepository reflectionRepository;
  late DefaultResolveAdaptiveDiscoverySignalsUseCase useCase;

  setUp(() {
    reflectionRepository = InMemoryReflectionRepository();
    useCase = DefaultResolveAdaptiveDiscoverySignalsUseCase(
      reflectionRepository: reflectionRepository,
    );
  });

  group('ResolveAdaptiveDiscoverySignalsUseCase', () {
    test('themes only: unions narrative themes from journey reflections', () async {
      final journey = Journey(
        id: JourneyId('journey-signals-1'),
        vision: JourneyVision('Grow with courage.'),
      );
      final themeA = NarrativeThemeId('courage');
      final themeB = NarrativeThemeId('perseverance');

      await _saveSubmittedReflectionWithThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [themeA, themeB],
      );
      await _saveSubmittedReflectionWithThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [themeA],
      );

      final signals = await useCase.execute(journey);

      expect(signals.hasThemes, isTrue);
      expect(signals.hasPatterns, isFalse);
      expect(
        signals.narrativeThemeIds.map((t) => t.value).toSet(),
        {'courage', 'perseverance'},
      );
    });

    test('patterns only: copies journey behavior patterns without themes', () async {
      final journey = _journeyWithConsistency();

      final signals = await useCase.execute(journey);

      expect(signals.hasThemes, isFalse);
      expect(signals.hasPatterns, isTrue);
      expect(signals.behaviorPatterns.single.type, BehaviorPatternType.consistency);
    });

    test('themes + patterns: includes both signal sources', () async {
      final journey = _journeyWithConsistency();
      await _saveSubmittedReflectionWithThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [NarrativeThemeId('service')],
      );

      final signals = await useCase.execute(journey);

      expect(signals.hasThemes, isTrue);
      expect(signals.hasPatterns, isTrue);
      expect(signals.narrativeThemeIds.single.value, 'service');
      expect(signals.behaviorPatterns, isNotEmpty);
    });

    test('no signals: empty themes and patterns', () async {
      final journey = Journey(
        id: JourneyId('journey-empty'),
        vision: JourneyVision('Start somewhere.'),
      );

      final signals = await useCase.execute(journey);

      expect(signals.isEmpty, isTrue);
      expect(signals.narrativeThemeIds, isEmpty);
      expect(signals.behaviorPatterns, isEmpty);
    });

    test('theme ids are sorted deterministically', () async {
      final journey = Journey(
        id: JourneyId('journey-sort'),
        vision: JourneyVision('Deterministic themes.'),
      );
      await _saveSubmittedReflectionWithThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [
          NarrativeThemeId('zebra'),
          NarrativeThemeId('alpha'),
        ],
      );

      final signals = await useCase.execute(journey);

      expect(
        signals.narrativeThemeIds.map((t) => t.value).toList(),
        ['alpha', 'zebra'],
      );
    });

    test(
      'themeLastExpressedAt tracks most recent submission per theme',
      () async {
        final journey = Journey(
          id: JourneyId('journey-recency'),
          vision: JourneyVision('Track theme recency.'),
        );
        final courage = NarrativeThemeId('courage');
        final service = NarrativeThemeId('service');

        await _saveSubmittedReflectionWithThemes(
          reflectionRepository,
          journeyId: journey.id,
          themes: [courage],
          submittedAt: DateTime.utc(2026, 1, 1),
        );
        await _saveSubmittedReflectionWithThemes(
          reflectionRepository,
          journeyId: journey.id,
          themes: [service],
          submittedAt: DateTime.utc(2026, 1, 2),
        );

        final signals = await useCase.execute(journey);

        expect(
          signals.narrativeThemeIds.map((t) => t.value).toSet(),
          {'courage', 'service'},
        );
        expect(
          signals.themeLastExpressedAt['courage'],
          DateTime.utc(2026, 1, 1),
        );
        expect(
          signals.themeLastExpressedAt['service'],
          DateTime.utc(2026, 1, 2),
        );
        expect(
          signals.themeLastExpressedAt['service']!
              .isAfter(signals.themeLastExpressedAt['courage']!),
          isTrue,
        );
      },
    );

    test(
      'D.1: unions DiscoveryProfile themes with Reflection themes',
      () async {
        final userId = UserId('dev-user');
        final profileRepository = InMemoryDiscoveryProfileRepository();
        await profileRepository.save(
          DiscoveryProfileFixture.create(
            userId: userId,
            narrativeThemeIds: [
              NarrativeThemeId('perseverance'),
              NarrativeThemeId('courage'),
            ],
          ),
        );

        final journey = Journey(
          id: JourneyId('journey-discovery-profile'),
          vision: JourneyVision('DiscoveryProfile contributes themes.'),
        );
        await _saveSubmittedReflectionWithThemes(
          reflectionRepository,
          journeyId: journey.id,
          themes: [NarrativeThemeId('service')],
        );

        final withProfile = DefaultResolveAdaptiveDiscoverySignalsUseCase(
          reflectionRepository: reflectionRepository,
          discoveryProfileThemeSource: RepositoryDiscoveryProfileThemeSource(
            discoveryProfileRepository: profileRepository,
            currentUserId: userId,
          ),
        );

        final signals = await withProfile.execute(journey);

        expect(
          signals.narrativeThemeIds.map((t) => t.value).toList(),
          ['courage', 'perseverance', 'service'],
        );
        expect(signals.themeLastExpressedAt.containsKey('service'), isTrue);
        expect(
          signals.themeLastExpressedAt.containsKey('perseverance'),
          isFalse,
        );
        expect(
          signals.inspirationThemeIds.map((t) => t.value).toList(),
          ['courage', 'perseverance'],
        );
      },
    );

    test(
      'D.1: DiscoveryProfile themes alone produce adaptive theme signals',
      () async {
        final userId = UserId('dev-user');
        final profileRepository = InMemoryDiscoveryProfileRepository();
        await profileRepository.save(
          DiscoveryProfileFixture.create(
            userId: userId,
            narrativeThemeIds: [NarrativeThemeId('leadership')],
          ),
        );

        final journey = Journey(
          id: JourneyId('journey-profile-only'),
          vision: JourneyVision('Profile-only themes.'),
        );

        final withProfile = DefaultResolveAdaptiveDiscoverySignalsUseCase(
          reflectionRepository: reflectionRepository,
          discoveryProfileThemeSource: RepositoryDiscoveryProfileThemeSource(
            discoveryProfileRepository: profileRepository,
            currentUserId: userId,
          ),
        );

        final signals = await withProfile.execute(journey);

        expect(signals.hasThemes, isTrue);
        expect(signals.narrativeThemeIds.single.value, 'leadership');
        expect(signals.themeLastExpressedAt, isEmpty);
        expect(signals.inspirationThemeIds.single.value, 'leadership');
      },
    );

    test(
      'D.1: empty DiscoveryProfileThemeSource leaves Reflection-only behavior',
      () async {
        final journey = Journey(
          id: JourneyId('journey-empty-source'),
          vision: JourneyVision('Empty discovery source.'),
        );
        await _saveSubmittedReflectionWithThemes(
          reflectionRepository,
          journeyId: journey.id,
          themes: [NarrativeThemeId('family')],
        );

        final withEmpty = DefaultResolveAdaptiveDiscoverySignalsUseCase(
          reflectionRepository: reflectionRepository,
          discoveryProfileThemeSource: const EmptyDiscoveryProfileThemeSource(),
        );

        final signals = await withEmpty.execute(journey);

        expect(signals.narrativeThemeIds.single.value, 'family');
      },
    );
  });

  group('AdaptiveDiscoverySignals', () {
    test('reports emptiness correctly', () {
      expect(AdaptiveDiscoverySignals().isEmpty, isTrue);
      expect(
        AdaptiveDiscoverySignals(
          narrativeThemeIds: [NarrativeThemeId('courage')],
        ).isEmpty,
        isFalse,
      );
    });
  });
}

Journey _journeyWithConsistency() {
  final evidence = [
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 1))
        .build(),
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 2))
        .build(),
  ];

  return Journey(
    id: JourneyId('journey-patterns'),
    vision: JourneyVision('Build consistency.'),
    behaviorPatterns: [
      BehaviorPattern(
        type: BehaviorPatternType.consistency,
        strength: const Strength(0.8),
        supportingEvidence: evidence,
        firstObservedAt: DateTime(2026, 8, 1),
        lastObservedAt: DateTime(2026, 8, 2),
      ),
    ],
  );
}

Future<void> _saveSubmittedReflectionWithThemes(
  InMemoryReflectionRepository repository, {
  required JourneyId journeyId,
  required List<NarrativeThemeId> themes,
  DateTime? submittedAt,
}) async {
  final at = submittedAt ?? DateTime.utc(2026, 1, 1);
  final reflection = Reflection(
    id: ReflectionId.generate(),
    journeyId: journeyId,
    createdAt: at,
    submittedAt: at,
    responses: const [JournalResponse(response: 'I showed up today.')],
    narrativeThemes: themes,
  );
  await repository.save(reflection);
}
