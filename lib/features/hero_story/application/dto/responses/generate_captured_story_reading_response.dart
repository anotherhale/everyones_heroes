import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

/// Response for [GenerateCapturedStoryReadingUseCase].
final class GenerateCapturedStoryReadingResponse {
  const GenerateCapturedStoryReadingResponse({
    required this.reading,
    this.idempotentReplay = false,
  });

  final CapturedStoryReading reading;
  final bool idempotentReplay;
}
