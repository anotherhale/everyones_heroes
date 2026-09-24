import 'package:eh_platform/src/shared_kernel/exceptions/validation_exception.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Minimal discoverable Story projection for adaptive Experience composition.
///
/// This is **not** a second Story aggregate. J.2 Slice 4 stores this shape in
/// the `discoverable_story_candidates` Postgres table (derived data) so
/// [DiscoverableStoryCandidatePort] can supply HS.8 candidates without
/// inventing a parallel Story model.
///
/// Theme IDs must be canonical Discovery catalog IDs
/// ([NarrativeThemeReferenceIds]). Unknown IDs fail validation at construction.
final class StoryCandidateRecord {
  StoryCandidateRecord({
    required this.storyId,
    required this.heroId,
    required this.title,
    required List<String> themeIds,
    required this.updatedAt,
  }) : themeIds = List.unmodifiable(_validateThemeIds(themeIds));

  final String storyId;
  final String heroId;
  final String title;

  /// Canonical Discovery opaque theme IDs (catalog-valid only).
  final List<String> themeIds;
  final DateTime updatedAt;

  static List<String> _validateThemeIds(List<String> themeIds) {
    if (themeIds.isEmpty) {
      throw const ValidationException(
        'StoryCandidateRecord requires at least one narrative theme ID.',
      );
    }
    if (themeIds.any((id) => id.trim().isEmpty)) {
      throw const ValidationException(
        'StoryCandidateRecord theme IDs must be non-empty strings.',
      );
    }
    final unknown = themeIds
        .where((id) => !NarrativeThemeReferenceIds.containsValue(id))
        .toList(growable: false);
    if (unknown.isNotEmpty) {
      throw ValidationException(
        'StoryCandidateRecord contains unknown theme IDs '
        '(not in Discovery catalog): ${unknown.join(', ')}',
      );
    }
    // Deterministic storage order: sorted unique.
    final unique = {...themeIds}.toList()..sort();
    return unique;
  }
}
