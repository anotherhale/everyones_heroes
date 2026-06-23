import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

sealed class EvidenceSource {
  const EvidenceSource();
}

final class ReflectionEvidenceSource extends EvidenceSource {
  const ReflectionEvidenceSource({required this.reflectionId});

  final ReflectionId reflectionId;

  @override
  bool operator ==(Object other) =>
      other is ReflectionEvidenceSource && reflectionId == other.reflectionId;

  @override
  int get hashCode => reflectionId.hashCode;
}

final class MissionEvidenceSource extends EvidenceSource {
  const MissionEvidenceSource({required this.missionId});

  final MissionId missionId;

  @override
  bool operator ==(Object other) =>
      other is MissionEvidenceSource && missionId == other.missionId;

  @override
  int get hashCode => missionId.hashCode;
}
