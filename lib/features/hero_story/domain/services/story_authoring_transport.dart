import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';

/// Subordinate AI transport used by [AiStoryShaper] (SB.11).
///
/// **Not** a parallel product shaping port. Application code selects shaping
/// through [StoryShaperPort] / [StoryShaperStrategyResolver] only.
///
/// Implementations call the EH AI proxy `POST /story-authoring` (or an
/// in-memory stand-in). Never mutates sessions or persists proposals.
abstract interface class StoryAuthoringTransport {
  Future<StoryAuthoringResponse> author(StoryAuthoringRequest request);
}

/// Minimized authoring input derived from a [StoryProposal].
///
/// Distinguishes SOURCE MATERIAL (Hero sections) from DERIVED UNDERSTANDING.
/// Does not include credentials, filesystem paths, or unrelated Hero state.
final class StoryAuthoringRequest {
  const StoryAuthoringRequest({
    this.purpose,
    this.themes = const [],
    this.themesUnsure = false,
    this.title,
    this.summary,
    this.understandingSummary,
    this.sections = const [],
  });

  final StoryBuilderPurpose? purpose;
  final List<StoryBuilderTheme> themes;
  final bool themesUnsure;
  final String? title;
  final String? summary;
  final String? understandingSummary;
  final List<StoryAuthoringSectionInput> sections;
}

/// One proposal section supplied as source material for authoring.
final class StoryAuthoringSectionInput {
  const StoryAuthoringSectionInput({
    required this.role,
    required this.sourceResponseIds,
    required this.contentOrigin,
    this.content,
    this.wasSkipped = false,
  });

  final StoryBuilderNarrativeRole role;
  final String? content;
  final List<StoryBuilderResponseId> sourceResponseIds;
  final StoryProposalContentOrigin contentOrigin;
  final bool wasSkipped;
}

/// Typed AI authoring result — never free-form provider prose as canonical.
final class StoryAuthoringResponse {
  const StoryAuthoringResponse({
    this.title,
    this.summary,
    this.sections = const [],
    this.warnings = const [],
    this.providerLabel,
    this.modelLabel,
    this.promptOrTemplateVersion,
  });

  final String? title;
  final String? summary;
  final List<StoryAuthoringSectionOutput> sections;
  final List<String> warnings;
  final String? providerLabel;
  final String? modelLabel;
  final String? promptOrTemplateVersion;
}

final class StoryAuthoringSectionOutput {
  const StoryAuthoringSectionOutput({
    required this.role,
    required this.sourceResponseIds,
    this.content,
  });

  final StoryBuilderNarrativeRole role;
  final String? content;
  final List<StoryBuilderResponseId> sourceResponseIds;
}
