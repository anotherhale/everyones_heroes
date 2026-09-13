import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Safe playable descriptor for an authoritative StoryRepresentation (HS.7).
///
/// Text content is included only for text-like formats from authoritative reps.
/// Media bytes are never embedded; callers use [LoadStoryMediaUseCase].
final class PlayableRepresentation {
  const PlayableRepresentation({
    required this.representationId,
    required this.format,
    required this.language,
    required this.hasText,
    required this.hasMedia,
    this.duration,
    this.textContent,
  });

  final StoryRepresentationId representationId;
  final StoryRepresentationFormat format;
  final LanguageCode language;
  final Duration? duration;
  final bool hasText;
  final bool hasMedia;

  /// Authoritative text body for text-like formats; null when media-only.
  final String? textContent;

  bool get isTextLike =>
      format == StoryRepresentationFormat.written ||
      format == StoryRepresentationFormat.transcript ||
      format == StoryRepresentationFormat.script ||
      format == StoryRepresentationFormat.shortForm ||
      format == StoryRepresentationFormat.longForm;
}
