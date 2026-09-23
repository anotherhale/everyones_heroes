import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';

/// Signals that may strengthen HS.8 Story composition rationale.
///
/// Built from Journey understanding inputs. Theme ids default empty until a
/// later Discovery/HS platform wiring phase supplies them.
final class AdaptiveDiscoverySignals {
  AdaptiveDiscoverySignals({
    List<String> narrativeThemeIds = const [],
    List<BehaviorPattern> behaviorPatterns = const [],
  })  : narrativeThemeIds = List.unmodifiable(narrativeThemeIds),
        behaviorPatterns = List.unmodifiable(behaviorPatterns);

  final List<String> narrativeThemeIds;
  final List<BehaviorPattern> behaviorPatterns;

  bool get hasThemes => narrativeThemeIds.isNotEmpty;

  bool get hasPatterns => behaviorPatterns.isNotEmpty;
}
