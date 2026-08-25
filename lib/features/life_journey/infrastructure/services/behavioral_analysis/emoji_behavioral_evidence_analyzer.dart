import 'package:everyonesheroes/core/ids/analyzer_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';

final class EmojiBehavioralEvidenceAnalyzer
    implements BehavioralEvidenceAnalyzer {
  const EmojiBehavioralEvidenceAnalyzer();

  @override
  BehavioralAnalyzerDescriptor get descriptor => BehavioralAnalyzerDescriptor(
    id: AnalyzerId.generate(),
    capabilities: {BehavioralAnalyzerCapability.emoji},
  );

  @override
  bool supports(BehavioralEvidenceAnalysisContext context) {
    return context.response is EmojiResponse;
  }

  @override
  Future<List<BehavioralEvidence>> analyze(
    BehavioralEvidenceAnalysisContext context,
  ) async {
    final response = context.response;

    if (response is! EmojiResponse) {
      return const [];
    }

    final type = _behaviorTypeFor(response.emotion);

    if (type == null) {
      return const [];
    }

    return [
      BehavioralEvidence(
        type: type,
        source: ReflectionEvidenceSource(reflectionId: context.reflectionId),
        strength: Strength(_strengthFor(response.emotion)),
        observedAt: DateTime.now(),
      ),
    ];
  }

  BehavioralEvidenceType? _behaviorTypeFor(ReflectionEmotion emotion) {
    switch (emotion) {
      case ReflectionEmotion.excited:
        return BehavioralEvidenceType.confidence;

      case ReflectionEmotion.proud:
        return BehavioralEvidenceType.confidence;

      case ReflectionEmotion.grateful:
        return BehavioralEvidenceType.connection;

      case ReflectionEmotion.frustrated:
        return BehavioralEvidenceType.resilience;

      case ReflectionEmotion.anxious:
        return BehavioralEvidenceType.fear;

      case ReflectionEmotion.overwhelmed:
        return BehavioralEvidenceType.vulnerability;

      case ReflectionEmotion.calm:
        return BehavioralEvidenceType.selfAwareness;

      case ReflectionEmotion.hopeful:
        return BehavioralEvidenceType.purpose;

      case ReflectionEmotion.neutral:
        return null;
    }
  }

  double _strengthFor(ReflectionEmotion emotion) {
    switch (emotion) {
      case ReflectionEmotion.excited:
      case ReflectionEmotion.proud:
      case ReflectionEmotion.grateful:
      case ReflectionEmotion.calm:
      case ReflectionEmotion.hopeful:
        return 0.8;

      case ReflectionEmotion.frustrated:
      case ReflectionEmotion.anxious:
      case ReflectionEmotion.overwhelmed:
        return 0.7;

      case ReflectionEmotion.neutral:
        return 0.0;
    }
  }
}
