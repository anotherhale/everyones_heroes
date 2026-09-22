import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_key_story_elements.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_narrative_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_significant_event.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_theme.dart';

/// Provider-independent Story Builder Understanding boundary (SB.8).
///
/// Separate from [StoryBuilderCoachPort] (next question) and HS.4
/// [StoryUnderstandingPort] (Story representation catalog proposals).
abstract interface class StoryBuilderUnderstandingPort {
  Future<StoryBuilderUnderstandingDraft> analyze(
    StoryBuilderUnderstandingRequest request,
  );
}

/// Minimized analysis input derived from [StoryBuilderSession] + SB.4 structure.
///
/// Does not include auth credentials, filesystem paths, or unrelated Hero state.
final class StoryBuilderUnderstandingRequest {
  const StoryBuilderUnderstandingRequest({
    this.purpose,
    this.themes = const [],
    this.themesUnsure = false,
    this.responses = const [],
    this.structureSections = const [],
  });

  final StoryBuilderPurpose? purpose;
  final List<StoryBuilderTheme> themes;
  final bool themesUnsure;
  final List<StoryBuilderUnderstandingResponseItem> responses;
  final List<StoryBuilderUnderstandingStructureSection> structureSections;
}

/// One Hero response eligible for analysis (text is untrusted user content).
final class StoryBuilderUnderstandingResponseItem {
  const StoryBuilderUnderstandingResponseItem({
    required this.id,
    required this.ordinal,
    this.narrativeRole,
    this.text,
    this.skipped = false,
  });

  final StoryBuilderResponseId id;
  final int ordinal;
  final StoryBuilderNarrativeRole? narrativeRole;
  final String? text;
  final bool skipped;
}

/// Structural slot from SB.4 (role → response provenance).
final class StoryBuilderUnderstandingStructureSection {
  const StoryBuilderUnderstandingStructureSection({
    required this.narrativeRole,
    required this.order,
    required this.sourceResponseIds,
    required this.wasSkipped,
    required this.hasSourceMaterial,
  });

  final StoryBuilderNarrativeRole narrativeRole;
  final int order;
  final List<StoryBuilderResponseId> sourceResponseIds;
  final bool wasSkipped;
  final bool hasSourceMaterial;
}

/// Provider-agnostic draft mapped into [StoryBuilderUnderstanding].
final class StoryBuilderUnderstandingDraft {
  const StoryBuilderUnderstandingDraft({
    this.themes = const [],
    this.narrativeElements = const [],
    this.keyElements = const UnderstoodKeyStoryElements(),
    this.significantEvents = const [],
    this.derivedSummary,
    this.providerLabel,
    this.modelLabel,
    this.promptOrTemplateVersion,
  });

  final List<UnderstoodTheme> themes;
  final List<UnderstoodNarrativeElement> narrativeElements;
  final UnderstoodKeyStoryElements keyElements;
  final List<UnderstoodSignificantEvent> significantEvents;
  final String? derivedSummary;
  final String? providerLabel;
  final String? modelLabel;
  final String? promptOrTemplateVersion;
}

final class StoryBuilderUnderstandingException implements Exception {
  const StoryBuilderUnderstandingException(this.message);

  final String message;

  @override
  String toString() => 'StoryBuilderUnderstandingException: $message';
}
