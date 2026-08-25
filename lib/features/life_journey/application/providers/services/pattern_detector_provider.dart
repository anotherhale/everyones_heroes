import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/patterns/rules/consistency_pattern_rule.dart';
import '../../../domain/patterns/rules/courage_pattern_rule.dart';
import '../../../domain/patterns/rules/leadership_pattern_rule.dart';
import '../../../domain/patterns/rules/recovery_pattern_rule.dart';
import '../../../domain/patterns/rules/responsibility_pattern_rule.dart';
import '../../../domain/patterns/rules/service_pattern_rule.dart';
import '../../../domain/services/pattern_detector.dart';
import '../../../infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart';

final patternDetectorProvider = Provider<PatternDetector>((ref) {
  return const RuleBasedPatternDetector(
    rules: [
      ConsistencyPatternRule(),
      CouragePatternRule(),
      LeadershipPatternRule(),
      RecoveryPatternRule(),
      ResponsibilityPatternRule(),
      ServicePatternRule(),
    ],
  );
});
