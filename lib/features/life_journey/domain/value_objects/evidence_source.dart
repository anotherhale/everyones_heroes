import 'package:everyonesheroes/core/ids/assessment_id.dart';
import 'package:everyonesheroes/core/ids/coaching_session_id.dart';
import 'package:everyonesheroes/core/ids/discovery_activity_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

sealed class EvidenceSource {
  const EvidenceSource();
}

/// Evidence derived from a submitted Reflection.
final class ReflectionEvidenceSource extends EvidenceSource {
  const ReflectionEvidenceSource({required this.reflectionId});

  final ReflectionId reflectionId;

  @override
  bool operator ==(Object other) =>
      other is ReflectionEvidenceSource && reflectionId == other.reflectionId;

  @override
  int get hashCode => reflectionId.hashCode;
}

/// Evidence derived from a completed Mission.
final class MissionEvidenceSource extends EvidenceSource {
  const MissionEvidenceSource({required this.missionId});

  final MissionId missionId;

  @override
  bool operator ==(Object other) =>
      other is MissionEvidenceSource && missionId == other.missionId;

  @override
  int get hashCode => missionId.hashCode;
}

/// Evidence gathered during a Discovery Activity.
final class DiscoveryEvidenceSource extends EvidenceSource {
  const DiscoveryEvidenceSource({required this.discoveryActivityId});

  final DiscoveryActivityId discoveryActivityId;

  @override
  bool operator ==(Object other) =>
      other is DiscoveryEvidenceSource &&
      discoveryActivityId == other.discoveryActivityId;

  @override
  int get hashCode => discoveryActivityId.hashCode;
}

/// Evidence imported from a structured assessment.
final class AssessmentEvidenceSource extends EvidenceSource {
  const AssessmentEvidenceSource({required this.assessmentId});

  final AssessmentId assessmentId;

  @override
  bool operator ==(Object other) =>
      other is AssessmentEvidenceSource && assessmentId == other.assessmentId;

  @override
  int get hashCode => assessmentId.hashCode;
}

/// Evidence observed during an AI or human coaching session.
final class CoachingEvidenceSource extends EvidenceSource {
  const CoachingEvidenceSource({required this.coachingSessionId});

  final CoachingSessionId coachingSessionId;

  @override
  bool operator ==(Object other) =>
      other is CoachingEvidenceSource &&
      coachingSessionId == other.coachingSessionId;

  @override
  int get hashCode => coachingSessionId.hashCode;
}
