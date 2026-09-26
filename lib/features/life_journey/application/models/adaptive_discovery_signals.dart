import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';

/// Application-facing understanding inputs for adaptive Hero/Story relevance.
///
/// Not a domain aggregate. Free of Riverpod/Flutter/repository dependencies.
///
/// Theme sources (D.1 deterministic union):
/// - Reflection.narrativeThemes for the current Journey
/// - DiscoveryProfile.narrativeThemeIds for the current user
///
/// Patterns: Journey.behaviorPatterns.
///
/// [narrativeThemeIds] is the historical theme union (sorted).
/// [themeLastExpressedAt] maps each theme value to the most recent Reflection
/// `submittedAt` (falling back to `createdAt`) that carried that theme.
/// DiscoveryProfile-only themes may appear in [narrativeThemeIds] without a
/// recency entry.
final class AdaptiveDiscoverySignals {
  AdaptiveDiscoverySignals({
    List<NarrativeThemeId> narrativeThemeIds = const [],
    List<BehaviorPattern> behaviorPatterns = const [],
    Map<String, DateTime> themeLastExpressedAt = const {},
  }) : narrativeThemeIds = List.unmodifiable(narrativeThemeIds),
       behaviorPatterns = List.unmodifiable(behaviorPatterns),
       themeLastExpressedAt = Map.unmodifiable(themeLastExpressedAt);

  final List<NarrativeThemeId> narrativeThemeIds;
  final List<BehaviorPattern> behaviorPatterns;

  /// Theme value → latest Reflection submission time expressing that theme.
  final Map<String, DateTime> themeLastExpressedAt;

  bool get hasThemes => narrativeThemeIds.isNotEmpty;

  bool get hasPatterns => behaviorPatterns.isNotEmpty;

  bool get hasThemeRecency => themeLastExpressedAt.isNotEmpty;

  bool get isEmpty => !hasThemes && !hasPatterns;

  /// Patterns that may strengthen thematic relevance (all current pattern types).
  List<BehaviorPattern> get strengtheningPatterns => behaviorPatterns;
}
