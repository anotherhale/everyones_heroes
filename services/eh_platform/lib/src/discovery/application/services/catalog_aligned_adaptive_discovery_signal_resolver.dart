import 'package:eh_platform/src/discovery/domain/services/narrative_theme_alignment.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/ports/adaptive_discovery_signal_port.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/reflection_repository.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';

/// Discovery application resolver: Reflection themes → catalog-aligned signals.
///
/// ```text
/// Reflection.narrativeThemes (stored observations)
///   → NarrativeThemeAlignment (catalog filter + legacy map)
///   → AdaptiveDiscoverySignals.narrativeThemeIds
///   → AdaptiveDiscoverySignals.themeLastExpressedAt
///   ∪ Journey.behaviorPatterns
/// ```
///
/// Experience Selection consumes the result; it does not interpret raw
/// reflection themes. Story candidate discovery remains fail-closed via
/// [DiscoverableStoryCandidatePort].
final class CatalogAlignedAdaptiveDiscoverySignalResolver
    implements AdaptiveDiscoverySignalPort {
  const CatalogAlignedAdaptiveDiscoverySignalResolver({
    required ReflectionRepository reflectionRepository,
  }) : _reflectionRepository = reflectionRepository;

  final ReflectionRepository _reflectionRepository;

  @override
  Future<AdaptiveDiscoverySignals> resolve(Journey journey) async {
    final reflections = await _reflectionRepository.findByJourneyId(journey.id);

    final themeLastExpressedAt = <String, DateTime>{};
    final rawThemes = <NarrativeThemeId>[];

    for (final reflection in reflections) {
      final expressedAt = reflection.submittedAt ?? reflection.createdAt;
      for (final themeId in reflection.narrativeThemes) {
        rawThemes.add(themeId);
        final aligned = NarrativeThemeAlignment.align(themeId);
        if (aligned == null) {
          continue;
        }
        final previous = themeLastExpressedAt[aligned.value];
        if (previous == null || expressedAt.isAfter(previous)) {
          themeLastExpressedAt[aligned.value] = expressedAt;
        }
      }
    }

    final aligned = NarrativeThemeAlignment.alignAll(rawThemes);

    return AdaptiveDiscoverySignals(
      narrativeThemeIds: [
        for (final id in aligned) id.value,
      ],
      behaviorPatterns: List.of(journey.behaviorPatterns),
      themeLastExpressedAt: themeLastExpressedAt,
    );
  }
}
