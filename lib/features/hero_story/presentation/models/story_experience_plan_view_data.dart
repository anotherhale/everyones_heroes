import 'package:flutter/foundation.dart';

import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Presentation model for a Story Experience Plan summary (HS.12.4).
@immutable
final class StoryExperiencePlanViewData {
  const StoryExperiencePlanViewData({
    required this.intention,
    required this.coreMessage,
    required this.emotionalArc,
    required this.keyMoments,
    required this.reflectionPrompt,
    required this.musicMood,
    required this.musicEnergy,
    required this.musicStyle,
    required this.musicRationale,
  });

  factory StoryExperiencePlanViewData.fromPlan(StoryExperiencePlan plan) {
    return StoryExperiencePlanViewData(
      intention: plan.intention,
      coreMessage: plan.coreMessage,
      emotionalArc: plan.emotionalArc,
      keyMoments: [
        for (final moment in plan.keyMoments)
          StoryExperienceMomentViewData(
            description: moment.description,
            startOffset: moment.sourceSpan.startOffset ?? 0,
            endOffset: moment.sourceSpan.endOffset ?? 0,
          ),
      ],
      reflectionPrompt: plan.reflectionPrompt,
      musicMood: plan.musicDirection.mood,
      musicEnergy: plan.musicDirection.energy,
      musicStyle: plan.musicDirection.style,
      musicRationale: plan.musicDirection.rationale,
    );
  }

  final StoryExperienceIntention intention;
  final String coreMessage;
  final StoryExperienceArc emotionalArc;
  final List<StoryExperienceMomentViewData> keyMoments;
  final String reflectionPrompt;
  final String musicMood;
  final String musicEnergy;
  final String musicStyle;
  final String musicRationale;

  String get intentionLabel => switch (intention) {
        StoryExperienceIntention.inspire => 'Inspire',
        StoryExperienceIntention.encourage => 'Encourage',
        StoryExperienceIntention.connect => 'Connect',
        StoryExperienceIntention.remember => 'Remember',
        StoryExperienceIntention.reflect => 'Reflect',
      };

  String get arcLabel => switch (emotionalArc) {
        StoryExperienceArc.challenge => 'Challenge',
        StoryExperienceArc.perseverance => 'Perseverance',
        StoryExperienceArc.transformation => 'Transformation',
        StoryExperienceArc.service => 'Service',
        StoryExperienceArc.discovery => 'Discovery',
        StoryExperienceArc.connection => 'Connection',
        StoryExperienceArc.remembrance => 'Remembrance',
      };
}

@immutable
final class StoryExperienceMomentViewData {
  const StoryExperienceMomentViewData({
    required this.description,
    required this.startOffset,
    required this.endOffset,
  });

  final String description;
  final int startOffset;
  final int endOffset;

  String get spanLabel => '[$startOffset–$endOffset]';
}
