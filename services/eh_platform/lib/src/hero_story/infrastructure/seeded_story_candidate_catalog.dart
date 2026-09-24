import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_record.dart';
import 'package:eh_platform/src/shared_kernel/exceptions/validation_exception.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Transitional deterministic Story candidate seed (J.2 Slice 3).
///
/// **Not** production content and **not** permanent architecture.
/// Platform Hero & Story persistence has not been migrated; this fixture
/// establishes the vertical path:
///
/// ```text
/// AdaptiveDiscoverySignals → DiscoverableStoryCandidatePort → seed → composer
/// ```
///
/// Replacement by real Hero & Story persistence should implement
/// [StoryCandidateSource] without changing the Experience port.
///
/// Unknown theme IDs fail validation at load time ([ValidationException]).
final class SeededStoryCandidateCatalog implements StoryCandidateSource {
  SeededStoryCandidateCatalog(List<StoryCandidateRecord> records)
      : _records = List.unmodifiable(_validateUnique(records));

  /// Architectural seed overlapping the canonical 14-theme catalog.
  ///
  /// At least one candidate includes `discovery` so Slice 2 analyzer signals
  /// (`CatalogAlignedNarrativeThemeResolver` → `discovery`) can demonstrate
  /// adaptive Story selection.
  factory SeededStoryCandidateCatalog.architecturalSeed() {
    return SeededStoryCandidateCatalog([
      StoryCandidateRecord(
        storyId: 'seed-story-finding-direction',
        heroId: 'seed-hero-a',
        title: '[Seed] Finding Direction',
        themeIds: const [
          // Overlaps Slice 2 analyzer output (always emits `discovery`).
          'discovery',
          'purpose',
        ],
        updatedAt: DateTime.utc(2026, 1, 10),
      ),
      StoryCandidateRecord(
        storyId: 'seed-story-rising-again',
        heroId: 'seed-hero-b',
        title: '[Seed] Rising Again',
        themeIds: const [
          'courage',
          'perseverance',
        ],
        updatedAt: DateTime.utc(2026, 1, 12),
      ),
      StoryCandidateRecord(
        storyId: 'seed-story-courage-alone',
        heroId: 'seed-hero-b',
        title: '[Seed] One Act of Courage',
        themeIds: const [
          'courage',
        ],
        updatedAt: DateTime.utc(2026, 1, 11),
      ),
      StoryCandidateRecord(
        storyId: 'seed-story-leading-through',
        heroId: 'seed-hero-c',
        title: '[Seed] Leading Through Service',
        themeIds: const [
          'leadership',
          'service',
        ],
        updatedAt: DateTime.utc(2026, 1, 8),
      ),
      StoryCandidateRecord(
        storyId: 'seed-story-second-wind',
        heroId: 'seed-hero-a',
        title: '[Seed] Second Wind',
        themeIds: const [
          'second-chances',
          'transformation',
        ],
        updatedAt: DateTime.utc(2026, 1, 9),
      ),
    ]);
  }

  /// Empty catalog — fail-closed adaptive Story path.
  factory SeededStoryCandidateCatalog.empty() =>
      SeededStoryCandidateCatalog(const []);

  final List<StoryCandidateRecord> _records;

  /// Exposed for tests / diagnostics (immutable).
  List<StoryCandidateRecord> get records => _records;

  @override
  Future<List<StoryCandidateRecord>> listCandidates() async => _records;

  static List<StoryCandidateRecord> _validateUnique(
    List<StoryCandidateRecord> records,
  ) {
    final seen = <String>{};
    for (final record in records) {
      if (!seen.add(record.storyId)) {
        throw ValidationException(
          'Duplicate Story candidate storyId in seed: ${record.storyId}',
        );
      }
      // Defense in depth: records already validate themes; re-check catalog.
      for (final themeId in record.themeIds) {
        if (!NarrativeThemeReferenceIds.containsValue(themeId)) {
          throw ValidationException(
            'Seed catalog rejected unknown theme ID: $themeId',
          );
        }
      }
    }
    return records;
  }
}
