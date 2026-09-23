import 'package:eh_platform/src/shared_kernel/ids/analyzer_id.dart';
import 'package:eh_platform/src/life_journey/domain/services/behavioral_analyzer_capability.dart';

final class BehavioralAnalyzerDescriptor {
  const BehavioralAnalyzerDescriptor({
    required this.id,
    required this.capabilities,
  });

  final AnalyzerId id;
  final Set<BehavioralAnalyzerCapability> capabilities;
}
