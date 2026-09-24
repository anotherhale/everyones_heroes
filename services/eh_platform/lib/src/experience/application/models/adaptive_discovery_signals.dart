import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';

/// Signals that may strengthen HS.8 Story composition rationale.
///
/// Consumption DTO for Experience Selection / [AdaptiveExperienceComposer].
/// Theme IDs are resolved by Discovery ([AdaptiveDiscoverySignalPort]) and
/// must be catalog-valid NarrativeTheme reference IDs (J.2).
///
/// [narrativeThemeIds] is the historical theme union (sorted).
/// [themeLastExpressedAt] maps each theme value to the most recent Reflection
/// submission time that carried that theme.
///
/// Patterns remain Journey understanding inputs (Life Journey authority).
final class AdaptiveDiscoverySignals {
  AdaptiveDiscoverySignals({
    List<String> narrativeThemeIds = const [],
    List<BehaviorPattern> behaviorPatterns = const [],
    Map<String, DateTime> themeLastExpressedAt = const {},
  })  : narrativeThemeIds = List.unmodifiable(narrativeThemeIds),
        behaviorPatterns = List.unmodifiable(behaviorPatterns),
        themeLastExpressedAt = Map.unmodifiable(themeLastExpressedAt);

  final List<String> narrativeThemeIds;
  final List<BehaviorPattern> behaviorPatterns;

  /// Theme value → latest Reflection submission time expressing that theme.
  final Map<String, DateTime> themeLastExpressedAt;

  bool get hasThemes => narrativeThemeIds.isNotEmpty;

  bool get hasPatterns => behaviorPatterns.isNotEmpty;

  bool get hasThemeRecency => themeLastExpressedAt.isNotEmpty;
}
