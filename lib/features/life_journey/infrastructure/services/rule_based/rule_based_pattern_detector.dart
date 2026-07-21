import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class RuleBasedPatternDetector implements PatternDetector {
  static const int minimumEvidenceCount = 3;

  @override
  List<Pattern> detect({required List<BehavioralEvidence> evidence}) {
    if (evidence.isEmpty) {
      return const [];
    }

    final grouped = <BehavioralEvidenceType, List<BehavioralEvidence>>{};

    for (final item in evidence) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return grouped.entries
        .where((entry) => entry.value.length >= minimumEvidenceCount)
        .map((entry) {
          final total = entry.value.fold<double>(
            0.0,
            (sum, evidence) => sum + evidence.strength.value,
          );

          final average = total / entry.value.length;

          return Pattern(
            type: entry.key,
            strength: Strength(average),
            supportingEvidence: entry.value,
          );
        })
        .toList(growable: false);
  }
}
