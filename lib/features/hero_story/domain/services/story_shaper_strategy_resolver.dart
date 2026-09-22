import 'package:everyonesheroes/features/hero_story/domain/enums/story_shaper_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_shaper.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';

/// Resolves [StoryShaperMode] to a [StoryShaperPort] (SB.10 / SB.11).
///
/// Independent of Story Builder interview mode ([StoryBuilderMode]).
abstract interface class StoryShaperStrategyResolver {
  StoryShaperPort resolve(StoryShaperMode mode);
}

/// Default resolver: deterministic offline shaper + injected AI shaper.
final class DefaultStoryShaperStrategyResolver
    implements StoryShaperStrategyResolver {
  const DefaultStoryShaperStrategyResolver({
    StoryShaperPort? deterministic,
    required StoryShaperPort ai,
  })  : _deterministic = deterministic ?? const DeterministicStoryShaper(),
        _ai = ai;

  final StoryShaperPort _deterministic;
  final StoryShaperPort _ai;

  @override
  StoryShaperPort resolve(StoryShaperMode mode) {
    return switch (mode) {
      StoryShaperMode.deterministic => _deterministic,
      StoryShaperMode.ai => _ai,
    };
  }
}
