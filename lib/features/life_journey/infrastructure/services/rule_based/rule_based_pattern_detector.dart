import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/pattern_rule.dart';

final class RuleBasedPatternDetector implements PatternDetector {
  const RuleBasedPatternDetector({required List<PatternRule> rules})
    : _rules = rules;

  final List<PatternRule> _rules;

  @override
  List<BehaviorPattern> detect({required List<BehavioralEvidence> evidence}) {
    return _rules
        .map((rule) => rule.detect(evidence))
        .whereType<BehaviorPattern>()
        .toList(growable: false);
  }
}
