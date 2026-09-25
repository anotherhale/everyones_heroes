import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Builds a Stable-Audio-ready instrumental prompt from experience intent.
///
/// Prefer creative-direction [musicPromptBrief] when present; otherwise derive
/// deterministically from [StoryExperiencePlan.musicDirection] + arc.
abstract final class ExperienceMusicPromptBuilder {
  static String build({
    required StoryExperiencePlan plan,
    PresentationCreativeDirection? creativeDirection,
  }) {
    final fromCreative = creativeDirection?.musicPromptBrief.trim();
    if (fromCreative != null && fromCreative.isNotEmpty) {
      return _ensureInstrumentalConstraint(fromCreative);
    }
    return _ensureInstrumentalConstraint(_fromPlan(plan));
  }

  static String _fromPlan(StoryExperiencePlan plan) {
    final music = plan.musicDirection;
    final arcHints = _arcHints(plan);
    return [
      'instrumental cinematic ${music.style} underscore',
      '${music.mood} mood',
      '${music.energy} energy',
      ...arcHints,
      'no vocals',
      'no lyrics',
    ].join(', ');
  }

  static List<String> _arcHints(StoryExperiencePlan plan) {
    // Map existing presentation purposes (quiet→resolve) into prompt language.
    return const [
      'restrained opening',
      'gradual tension',
      'hopeful build',
      'expansive emotional peak',
      'warm resolved ending',
    ];
  }

  static List<String> intensityHintsFromDirection(
    PresentationCreativeDirection? direction,
  ) {
    if (direction == null) {
      return MusicIntensityLabel.values.map((e) => e.name).toList();
    }
    return direction.intensityProgression
        .map((s) => '${s.purpose.name}:${s.intensity.name}')
        .toList();
  }

  static String describeMusicDirection(StoryExperienceMusicDirection music) {
    return '${music.mood}/${music.energy}/${music.style}';
  }

  static String _ensureInstrumentalConstraint(String prompt) {
    final lower = prompt.toLowerCase();
    final parts = <String>[prompt.trim()];
    if (!lower.contains('instrumental')) {
      parts.add('instrumental');
    }
    if (!lower.contains('no vocals')) {
      parts.add('no vocals');
    }
    if (!lower.contains('no lyrics')) {
      parts.add('no lyrics');
    }
    return parts.join(', ');
  }

  /// Linear volume for Strategy A intensity automation (under speech).
  static double volumeForIntensity(MusicIntensityLabel intensity) {
    return switch (intensity) {
      MusicIntensityLabel.quiet => 0.18,
      MusicIntensityLabel.tension => 0.26,
      MusicIntensityLabel.build => 0.34,
      MusicIntensityLabel.expansive => 0.42,
      MusicIntensityLabel.resolve => 0.28,
    };
  }

  static double volumeForPurpose(StoryExperiencePresentationPurpose purpose) {
    final stem = stemForPresentationPurpose(purpose);
    if (stem == null) {
      // Turning-point intentional silence → near mute on the bed.
      return 0.0;
    }
    return switch (stem) {
      StoryExperienceDemoStem.quiet =>
        volumeForIntensity(MusicIntensityLabel.quiet),
      StoryExperienceDemoStem.tension =>
        volumeForIntensity(MusicIntensityLabel.tension),
      StoryExperienceDemoStem.build =>
        volumeForIntensity(MusicIntensityLabel.build),
      StoryExperienceDemoStem.expansive =>
        volumeForIntensity(MusicIntensityLabel.expansive),
      StoryExperienceDemoStem.resolve =>
        volumeForIntensity(MusicIntensityLabel.resolve),
    };
  }

  static MusicIntensityLabel? intensityForPurpose(
    StoryExperiencePresentationPurpose purpose,
  ) {
    final stem = stemForPresentationPurpose(purpose);
    if (stem == null) return null;
    return switch (stem) {
      StoryExperienceDemoStem.quiet => MusicIntensityLabel.quiet,
      StoryExperienceDemoStem.tension => MusicIntensityLabel.tension,
      StoryExperienceDemoStem.build => MusicIntensityLabel.build,
      StoryExperienceDemoStem.expansive => MusicIntensityLabel.expansive,
      StoryExperienceDemoStem.resolve => MusicIntensityLabel.resolve,
    };
  }
}
