import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';

/// Application-facing understanding inputs for adaptive Hero/Story relevance.
///
/// Not a domain aggregate. Free of Riverpod/Flutter/repository dependencies.
/// Sourced from Journey behavior patterns and Reflection NarrativeThemeIds.
final class AdaptiveDiscoverySignals {
  AdaptiveDiscoverySignals({
    List<NarrativeThemeId> narrativeThemeIds = const [],
    List<BehaviorPattern> behaviorPatterns = const [],
  }) : narrativeThemeIds = List.unmodifiable(narrativeThemeIds),
       behaviorPatterns = List.unmodifiable(behaviorPatterns);

  final List<NarrativeThemeId> narrativeThemeIds;
  final List<BehaviorPattern> behaviorPatterns;

  bool get hasThemes => narrativeThemeIds.isNotEmpty;

  bool get hasPatterns => behaviorPatterns.isNotEmpty;

  bool get isEmpty => !hasThemes && !hasPatterns;

  /// Patterns that may strengthen thematic relevance (all current pattern types).
  List<BehaviorPattern> get strengtheningPatterns => behaviorPatterns;
}
