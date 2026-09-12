import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

final class CompleteStoryCaptureRequest {
  const CompleteStoryCaptureRequest({
    required this.sessionId,
    required this.heroId,
    required this.storyId,
    required this.representationId,
    required this.originalLanguage,
    required this.mediaBytes,
    this.title,
    this.originalSourceDescription,
    this.contentType,
    this.checksum,
    this.duration,
    this.occurredAt,
  });

  /// Application idempotency key for a capture workflow (not a domain id).
  final String sessionId;
  final HeroId heroId;
  final StoryId storyId;
  final StoryRepresentationId representationId;
  final LanguageCode originalLanguage;
  final Uint8List mediaBytes;
  final StoryTitle? title;
  final String? originalSourceDescription;
  final String? contentType;
  final String? checksum;
  final Duration? duration;
  final DateTime? occurredAt;
}
