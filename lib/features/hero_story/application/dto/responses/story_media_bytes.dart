import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

/// Media bytes retrieved for an authoritative, discoverable representation.
final class StoryMediaBytes {
  const StoryMediaBytes({
    required this.storyId,
    required this.representationId,
    required this.format,
    required this.bytes,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
  final StoryRepresentationFormat format;
  final Uint8List bytes;
}
