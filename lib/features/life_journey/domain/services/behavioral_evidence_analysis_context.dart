import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class BehavioralEvidenceAnalysisContext {
  const BehavioralEvidenceAnalysisContext({
    required this.reflectionId,
    required this.response,
  });

  final ReflectionId reflectionId;
  final ReflectionResponse response;
}
