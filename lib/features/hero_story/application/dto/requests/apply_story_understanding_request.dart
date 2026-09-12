import 'package:everyonesheroes/core/ids/story_understanding_id.dart';

final class ApplyStoryUnderstandingRequest {
  const ApplyStoryUnderstandingRequest({
    required this.understandingId,
    this.applyClassification = false,
    this.applySuitability = false,
    this.applySpirituality = false,
    this.acknowledgeStale = false,
    this.at,
  });

  final StoryUnderstandingId understandingId;
  final bool applyClassification;
  final bool applySuitability;
  final bool applySpirituality;
  final bool acknowledgeStale;
  final DateTime? at;
}
