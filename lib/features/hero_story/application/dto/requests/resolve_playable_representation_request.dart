import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Resolves the primary authoritative playable representation (HS.7 D3).
final class ResolvePlayableRepresentationRequest {
  const ResolvePlayableRepresentationRequest({
    required this.storyId,
    this.preferredLanguage,
    this.representationId,
  });

  final StoryId storyId;
  final LanguageCode? preferredLanguage;

  /// When set, selects this authoritative representation if eligible.
  final StoryRepresentationId? representationId;
}
