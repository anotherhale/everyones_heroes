import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/user_id.dart';

/// API / query DTOs — never expose raw aggregates across the HTTP boundary.
final class JourneySummaryDto {
  const JourneySummaryDto({
    required this.journeyId,
    required this.vision,
    required this.currentChapter,
    required this.behaviorPatternTypes,
  });

  final String journeyId;
  final String vision;
  final String currentChapter;
  final List<String> behaviorPatternTypes;

  Map<String, Object?> toJson() => {
    'journeyId': journeyId,
    'vision': vision,
    'currentChapter': currentChapter,
    'behaviorPatternTypes': behaviorPatternTypes,
  };

  factory JourneySummaryDto.fromJourney(Journey journey) {
    return JourneySummaryDto(
      journeyId: journey.id.value,
      vision: journey.vision.value,
      currentChapter: journey.currentChapter.name,
      behaviorPatternTypes: journey.behaviorPatterns
          .map((p) => p.type.name)
          .toList(),
    );
  }
}

final class BehaviorPatternDto {
  const BehaviorPatternDto({
    required this.type,
    required this.strength,
    required this.observationCount,
    required this.firstObservedAt,
    required this.lastObservedAt,
  });

  final String type;
  final double strength;
  final int observationCount;
  final String firstObservedAt;
  final String lastObservedAt;

  Map<String, Object?> toJson() => {
    'type': type,
    'strength': strength,
    'observationCount': observationCount,
    'firstObservedAt': firstObservedAt,
    'lastObservedAt': lastObservedAt,
  };

  factory BehaviorPatternDto.fromDomain(BehaviorPattern pattern) {
    return BehaviorPatternDto(
      type: pattern.type.name,
      strength: pattern.strength.value,
      observationCount: pattern.observationCount,
      firstObservedAt: pattern.firstObservedAt.toUtc().toIso8601String(),
      lastObservedAt: pattern.lastObservedAt.toUtc().toIso8601String(),
    );
  }
}

final class BehavioralEvidenceDto {
  const BehavioralEvidenceDto({
    required this.type,
    required this.strength,
    required this.observedAt,
    required this.sourceKind,
    required this.sourceId,
  });

  final String type;
  final double strength;
  final String observedAt;
  final String sourceKind;
  final String sourceId;

  Map<String, Object?> toJson() => {
    'type': type,
    'strength': strength,
    'observedAt': observedAt,
    'sourceKind': sourceKind,
    'sourceId': sourceId,
  };

  factory BehavioralEvidenceDto.fromDomain(BehavioralEvidence evidence) {
    final source = evidence.source;
    final (kind, id) = switch (source) {
      ReflectionEvidenceSource(:final reflectionId) => (
        'reflection',
        reflectionId.value,
      ),
      MissionEvidenceSource(:final missionId) => ('mission', missionId.value),
      DiscoveryEvidenceSource(:final discoveryActivityId) => (
        'discovery',
        discoveryActivityId.value,
      ),
      AssessmentEvidenceSource(:final assessmentId) => (
        'assessment',
        assessmentId.value,
      ),
      CoachingEvidenceSource(:final coachingSessionId) => (
        'coaching',
        coachingSessionId.value,
      ),
    };
    return BehavioralEvidenceDto(
      type: evidence.type.name,
      strength: evidence.strength.value,
      observedAt: evidence.observedAt.toUtc().toIso8601String(),
      sourceKind: kind,
      sourceId: id,
    );
  }
}

final class UnderstandingDto {
  const UnderstandingDto({
    required this.journeyId,
    required this.patterns,
    required this.recentEvidence,
  });

  final String journeyId;
  final List<BehaviorPatternDto> patterns;
  final List<BehavioralEvidenceDto> recentEvidence;

  Map<String, Object?> toJson() => {
    'journeyId': journeyId,
    'patterns': patterns.map((p) => p.toJson()).toList(),
    'recentEvidence': recentEvidence.map((e) => e.toJson()).toList(),
  };
}

final class ReflectionDto {
  const ReflectionDto({
    required this.reflectionId,
    required this.journeyId,
    required this.createdAt,
    required this.submittedAt,
    required this.responseCount,
    required this.evidenceCount,
  });

  final String reflectionId;
  final String journeyId;
  final String createdAt;
  final String? submittedAt;
  final int responseCount;
  final int evidenceCount;

  Map<String, Object?> toJson() => {
    'reflectionId': reflectionId,
    'journeyId': journeyId,
    'createdAt': createdAt,
    'submittedAt': submittedAt,
    'responseCount': responseCount,
    'evidenceCount': evidenceCount,
  };

  factory ReflectionDto.fromDomain(Reflection reflection) {
    return ReflectionDto(
      reflectionId: reflection.id.value,
      journeyId: reflection.journeyId.value,
      createdAt: reflection.createdAt.toUtc().toIso8601String(),
      submittedAt: reflection.submittedAt?.toUtc().toIso8601String(),
      responseCount: reflection.responses.length,
      evidenceCount: reflection.behavioralEvidence.length,
    );
  }
}

final class SubmitReflectionResultDto {
  const SubmitReflectionResultDto({
    required this.reflection,
    required this.understanding,
  });

  final ReflectionDto reflection;
  final UnderstandingDto understanding;

  Map<String, Object?> toJson() => {
    'reflection': reflection.toJson(),
    'understanding': understanding.toJson(),
  };
}

/// Authenticated caller context (Identity lite).
final class PlatformPrincipal {
  const PlatformPrincipal({required this.userId});

  final UserId userId;
}

typedef JourneyIdWire = JourneyId;
typedef ReflectionIdWire = ReflectionId;
