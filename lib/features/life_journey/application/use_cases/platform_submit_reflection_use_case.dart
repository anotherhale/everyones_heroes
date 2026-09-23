import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/submit_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_client.dart';

/// Platform-authoritative SubmitReflection — Flutter does not run H.2 locally.
///
/// After a successful platform submit, hydrates the local Journey cache so
/// Experience selection (still client-side until a later phase) can read
/// non-authoritative pattern snapshots.
final class PlatformSubmitReflectionUseCase
    implements SubmitReflectionUseCase {
  const PlatformSubmitReflectionUseCase({
    required this.client,
    required this.journeyRepository,
    required this.reflectionRepository,
  });

  final EhPlatformClient client;
  final JourneyRepository journeyRepository;
  final ReflectionRepository reflectionRepository;

  @override
  Future<Result<Reflection>> execute(SubmitReflectionRequest request) async {
    try {
      final dto = await client.submitReflection(
        reflectionId: request.reflectionId.value,
        idempotencyKey: 'submit-${request.reflectionId.value}',
      );

      final understanding =
          dto['understanding'] as Map<String, dynamic>? ?? const {};
      await _hydrateJourneyCache(understanding);

      final reflectionDto =
          dto['reflection'] as Map<String, dynamic>? ?? const {};
      final reflection = await _hydrateReflectionCache(
        request.reflectionId,
        reflectionDto,
        understanding,
      );

      return Success(reflection);
    } on EhPlatformApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Platform submit failed: $e');
    }
  }

  Future<void> _hydrateJourneyCache(Map<String, dynamic> understanding) async {
    final journeyIdRaw = understanding['journeyId'] as String?;
    if (journeyIdRaw == null) {
      return;
    }
    final journeyId = JourneyId(journeyIdRaw);
    final existing = await journeyRepository.findById(journeyId);

    final patternsJson = understanding['patterns'] as List? ?? const [];
    final patterns = <BehaviorPattern>[];
    for (final raw in patternsJson) {
      if (raw is! Map) continue;
      final typeName = raw['type'] as String?;
      final strength = (raw['strength'] as num?)?.toDouble() ?? 0.5;
      final first = DateTime.tryParse(raw['firstObservedAt'] as String? ?? '') ??
          DateTime.now().toUtc();
      final last = DateTime.tryParse(raw['lastObservedAt'] as String? ?? '') ??
          first;
      final count = (raw['observationCount'] as num?)?.toInt() ?? 2;
      if (typeName == null) continue;
      final supporting = List.generate(
        count < 2 ? 2 : count,
        (i) => BehavioralEvidence(
          type: BehavioralEvidenceType.discipline,
          source: ReflectionEvidenceSource(reflectionId: ReflectionId('cache-$i')),
          strength: Strength(strength),
          observedAt: first.add(Duration(minutes: i)),
        ),
      );
      patterns.add(
        BehaviorPattern(
          type: BehaviorPatternType.values.byName(typeName),
          strength: Strength(strength),
          supportingEvidence: supporting,
          firstObservedAt: first,
          lastObservedAt: last,
        ),
      );
    }

    final journey = existing ??
        Journey(
          id: journeyId,
          vision: JourneyVision(
            (understanding['vision'] as String?) ?? 'Platform journey',
          ),
          currentChapter: JourneyChapter.awakening,
        );

    // Replace behavioral state from platform snapshot (cache only).
    journey.updateBehaviorPatterns(patterns);
    journey.pullDomainEvents(); // discard — Flutter must not publish H.2 events
    await journeyRepository.save(journey);
  }

  Future<Reflection> _hydrateReflectionCache(
    ReflectionId reflectionId,
    Map<String, dynamic> reflectionDto,
    Map<String, dynamic> understanding,
  ) async {
    final existing = await reflectionRepository.findById(reflectionId);
    if (existing != null) {
      if (!existing.isSubmitted) {
        // Local draft may exist; mark submitted semantically by re-save after
        // platform authority already submitted. Prefer loading platform truth.
      }
      return existing;
    }

    final journeyId = JourneyId(
      reflectionDto['journeyId'] as String? ??
          understanding['journeyId'] as String? ??
          JourneyId.generate().value,
    );

    final reflection = Reflection(
      id: reflectionId,
      journeyId: journeyId,
      createdAt: DateTime.tryParse(reflectionDto['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      submittedAt:
          DateTime.tryParse(reflectionDto['submittedAt'] as String? ?? '') ??
              DateTime.now().toUtc(),
    );
    await reflectionRepository.save(reflection);
    return reflection;
  }
}
