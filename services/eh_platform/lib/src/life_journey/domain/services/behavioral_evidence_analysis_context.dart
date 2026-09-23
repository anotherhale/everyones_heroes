import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';

final class BehavioralEvidenceAnalysisContext {
  const BehavioralEvidenceAnalysisContext({
    required this.reflectionId,
    required this.response,
  });

  final ReflectionId reflectionId;
  final ReflectionResponse response;
}
