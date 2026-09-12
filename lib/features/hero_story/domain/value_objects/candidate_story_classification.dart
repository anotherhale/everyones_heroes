import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';

/// Non-authoritative proposed StoryClassification dimensions.
final class CandidateStoryClassification extends ValueObject {
  CandidateStoryClassification({
    Iterable<StorySubject>? subjects,
    Iterable<StoryChallenge>? challenges,
    Iterable<NarrativeThemeId>? narrativeThemeIds,
    Iterable<StoryOutcome>? outcomes,
    Iterable<EmotionalCharacter>? emotionalCharacters,
    this.audience,
    this.geography,
  }) : subjects = List.unmodifiable(
         (subjects ?? const <StorySubject>[]).toSet().toList(),
       ),
       challenges = List.unmodifiable(
         (challenges ?? const <StoryChallenge>[]).toSet().toList(),
       ),
       narrativeThemeIds = List.unmodifiable(
         (narrativeThemeIds ?? const <NarrativeThemeId>[]).toSet().toList(),
       ),
       outcomes = List.unmodifiable(
         (outcomes ?? const <StoryOutcome>[]).toSet().toList(),
       ),
       emotionalCharacters = List.unmodifiable(
         (emotionalCharacters ?? const <EmotionalCharacter>[])
             .toSet()
             .toList(),
       );

  static final CandidateStoryClassification empty =
      CandidateStoryClassification();

  final List<StorySubject> subjects;
  final List<StoryChallenge> challenges;
  final List<NarrativeThemeId> narrativeThemeIds;
  final List<StoryOutcome> outcomes;
  final List<EmotionalCharacter> emotionalCharacters;
  final StoryAudience? audience;
  final StoryGeography? geography;

  bool get isEmpty =>
      subjects.isEmpty &&
      challenges.isEmpty &&
      narrativeThemeIds.isEmpty &&
      outcomes.isEmpty &&
      emotionalCharacters.isEmpty &&
      audience == null &&
      geography == null;

  StoryClassification toAuthoritative() {
    return StoryClassification(
      subjects: subjects,
      challenges: challenges,
      narrativeThemeIds: narrativeThemeIds,
      outcomes: outcomes,
      emotionalCharacters: emotionalCharacters,
      audience: audience,
      geography: geography,
    );
  }

  @override
  List<Object?> get equalityProps => [
    ...subjects,
    ...challenges,
    ...narrativeThemeIds,
    ...outcomes,
    ...emotionalCharacters,
    audience,
    geography,
  ];
}
