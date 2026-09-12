import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// A language/format presentation of a Story.
///
/// AI-generated representations are non-authoritative until approved.
final class StoryRepresentation extends Entity<StoryRepresentationId> {
  StoryRepresentation({
    required StoryRepresentationId id,
    required this.language,
    required this.format,
    required this.origin,
    this.mediaReference,
    this.textContent,
    this.sourceRepresentationId,
    this.duration,
    this.isAiGenerated = false,
    this.isApproved = false,
  }) : super(id) {
    if (mediaReference == null &&
        (textContent == null || textContent!.trim().isEmpty)) {
      throw ArgumentError(
        'Story representation requires media reference or text content.',
      );
    }

    if (origin == RepresentationOrigin.translated &&
        sourceRepresentationId == null) {
      throw ArgumentError(
        'Translated representations must reference a source representation.',
      );
    }

    if (duration != null && duration!.isNegative) {
      throw ArgumentError('Representation duration cannot be negative.');
    }
  }

  final LanguageCode language;
  final StoryRepresentationFormat format;
  final RepresentationOrigin origin;
  final MediaReference? mediaReference;
  final String? textContent;
  final StoryRepresentationId? sourceRepresentationId;
  final Duration? duration;
  final bool isAiGenerated;
  final bool isApproved;

  /// Authoritative only when not AI-generated, or AI-generated and approved.
  bool get isAuthoritative => !isAiGenerated || isApproved;

  StoryRepresentation approve() {
    if (!isAiGenerated) {
      return this;
    }

    return StoryRepresentation(
      id: id,
      language: language,
      format: format,
      origin: origin,
      mediaReference: mediaReference,
      textContent: textContent,
      sourceRepresentationId: sourceRepresentationId,
      duration: duration,
      isAiGenerated: isAiGenerated,
      isApproved: true,
    );
  }

  /// Returns a copy with replaced text (used for human draft edits).
  StoryRepresentation withTextContent(String textContent) {
    return StoryRepresentation(
      id: id,
      language: language,
      format: format,
      origin: origin,
      mediaReference: mediaReference,
      textContent: textContent,
      sourceRepresentationId: sourceRepresentationId,
      duration: duration,
      isAiGenerated: isAiGenerated,
      isApproved: isApproved,
    );
  }
}
