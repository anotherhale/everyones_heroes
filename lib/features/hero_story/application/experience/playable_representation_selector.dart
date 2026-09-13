import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Deterministic language/format selection for authoritative Story representations (HS.7 D3).
///
/// Language priority:
/// 1. explicitly requested/preferred language, when supplied
/// 2. canonical/default Story language ([originalLanguage])
/// 3. otherwise the highest-priority authoritative representation by format + stable id
///
/// Format priority (explicit, non-personalized):
/// audio → video → written → script → shortForm → longForm → transcript
///
/// Does not use personalization, embeddings, semantic ranking, or device-locale inference.
final class PlayableRepresentationSelector {
  const PlayableRepresentationSelector._();

  /// Deterministic format priority for HS.7 MVP consumption.
  static const List<StoryRepresentationFormat> formatPriority = [
    StoryRepresentationFormat.audio,
    StoryRepresentationFormat.video,
    StoryRepresentationFormat.written,
    StoryRepresentationFormat.script,
    StoryRepresentationFormat.shortForm,
    StoryRepresentationFormat.longForm,
    StoryRepresentationFormat.transcript,
  ];

  static int formatRank(StoryRepresentationFormat format) {
    final index = formatPriority.indexOf(format);
    return index < 0 ? formatPriority.length : index;
  }

  /// Selects a single authoritative representation using D3 priority rules.
  ///
  /// Returns null when [candidates] contains no authoritative representations.
  static StoryRepresentation? select({
    required Iterable<StoryRepresentation> candidates,
    required LanguageCode originalLanguage,
    LanguageCode? preferredLanguage,
  }) {
    final authoritative = candidates
        .where((representation) => representation.isAuthoritative)
        .toList(growable: false);

    if (authoritative.isEmpty) {
      return null;
    }

    if (preferredLanguage != null) {
      final preferred = _bestInLanguage(authoritative, preferredLanguage);
      if (preferred != null) {
        return preferred;
      }
    }

    final original = _bestInLanguage(authoritative, originalLanguage);
    if (original != null) {
      return original;
    }

    return _bestOverall(authoritative);
  }

  static List<StoryRepresentation> sortAuthoritative(
    Iterable<StoryRepresentation> candidates, {
    required LanguageCode originalLanguage,
    LanguageCode? preferredLanguage,
  }) {
    final authoritative = candidates
        .where((representation) => representation.isAuthoritative)
        .toList();

    authoritative.sort(
      (a, b) => _compare(
        a,
        b,
        originalLanguage: originalLanguage,
        preferredLanguage: preferredLanguage,
      ),
    );
    return List.unmodifiable(authoritative);
  }

  static StoryRepresentation? _bestInLanguage(
    List<StoryRepresentation> candidates,
    LanguageCode language,
  ) {
    final inLanguage = candidates
        .where((representation) => representation.language == language)
        .toList(growable: false);
    if (inLanguage.isEmpty) {
      return null;
    }
    return _bestOverall(inLanguage);
  }

  static StoryRepresentation? _bestOverall(
    List<StoryRepresentation> candidates,
  ) {
    if (candidates.isEmpty) {
      return null;
    }
    final sorted = [...candidates]
      ..sort((a, b) => _compareFormatsThenId(a, b));
    return sorted.first;
  }

  static int _compare(
    StoryRepresentation a,
    StoryRepresentation b, {
    required LanguageCode originalLanguage,
    LanguageCode? preferredLanguage,
  }) {
    final languageRankA = _languageRank(
      a.language,
      preferredLanguage: preferredLanguage,
      originalLanguage: originalLanguage,
    );
    final languageRankB = _languageRank(
      b.language,
      preferredLanguage: preferredLanguage,
      originalLanguage: originalLanguage,
    );
    if (languageRankA != languageRankB) {
      return languageRankA.compareTo(languageRankB);
    }
    return _compareFormatsThenId(a, b);
  }

  static int _languageRank(
    LanguageCode language, {
    required LanguageCode? preferredLanguage,
    required LanguageCode originalLanguage,
  }) {
    if (preferredLanguage != null && language == preferredLanguage) {
      return 0;
    }
    if (language == originalLanguage) {
      return 1;
    }
    return 2;
  }

  static int _compareFormatsThenId(
    StoryRepresentation a,
    StoryRepresentation b,
  ) {
    final formatCompare = formatRank(a.format).compareTo(formatRank(b.format));
    if (formatCompare != 0) {
      return formatCompare;
    }
    return a.id.value.compareTo(b.id.value);
  }
}
