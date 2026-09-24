import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';

/// Signals that may strengthen HS.8 Story composition rationale.
///
/// Consumption DTO for Experience Selection / [AdaptiveExperienceComposer].
/// Theme IDs are resolved by Discovery ([AdaptiveDiscoverySignalPort]) and
/// must be catalog-valid NarrativeTheme reference IDs (J.2).
///
/// Patterns remain Journey understanding inputs (Life Journey authority).
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
