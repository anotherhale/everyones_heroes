import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';

/// Parses and validates EH AI proxy creative-direction responses (Experiment A).
///
/// Invalid or psychologically-prohibited output is rejected — never repaired.
abstract final class CreativeDirectionResponseParser {
  static const Set<String> forbiddenKeys = {
    'personality',
    'attachmentStyle',
    'trauma',
    'traumaLevel',
    'mentalHealth',
    'diagnosis',
    'resilienceScore',
    'emotionalHealth',
    'psychologicalState',
    'personalityTraits',
    'psychologicalProfile',
    'inferredMotivation',
    'behavioralTendency',
    'behavioralPattern',
  };

  static PresentationCreativeDirection parse(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw CreativeDirectionException(
        'Malformed creative-direction response: $e',
      );
    }

    if (decoded is! Map) {
      throw const CreativeDirectionException(
        'Creative-direction response must be a JSON object.',
      );
    }
    final json = Map<String, dynamic>.from(decoded);
    _rejectForbidden(json);

    final narrationEmphasis =
        (json['narrationEmphasis'] as String?)?.trim() ?? '';
    final pacingGuidance = (json['pacingGuidance'] as String?)?.trim() ?? '';
    final musicPromptBrief =
        (json['musicPromptBrief'] as String?)?.trim() ?? '';

    if (narrationEmphasis.isEmpty) {
      throw const CreativeDirectionException(
        'Creative-direction response missing narrationEmphasis.',
      );
    }
    if (pacingGuidance.isEmpty) {
      throw const CreativeDirectionException(
        'Creative-direction response missing pacingGuidance.',
      );
    }
    if (musicPromptBrief.isEmpty) {
      throw const CreativeDirectionException(
        'Creative-direction response missing musicPromptBrief.',
      );
    }

    final progressionRaw = json['intensityProgression'];
    if (progressionRaw is! List || progressionRaw.isEmpty) {
      throw const CreativeDirectionException(
        'Creative-direction response missing intensityProgression.',
      );
    }

    final progression = <CreativeIntensityStep>[];
    for (final item in progressionRaw) {
      if (item is! Map) {
        throw const CreativeDirectionException(
          'intensityProgression entries must be objects.',
        );
      }
      final step = Map<String, dynamic>.from(item);
      _rejectForbidden(step);
      final purposeRaw = (step['purpose'] as String?)?.trim() ?? '';
      final intensityRaw = (step['intensity'] as String?)?.trim() ?? '';
      if (purposeRaw.isEmpty || intensityRaw.isEmpty) {
        throw const CreativeDirectionException(
          'intensityProgression entries require purpose and intensity.',
        );
      }
      late final StoryExperiencePresentationPurpose purpose;
      late final MusicIntensityLabel intensity;
      try {
        purpose = StoryExperiencePresentationPurpose.values.byName(purposeRaw);
      } on ArgumentError {
        throw CreativeDirectionException('Unknown purpose: $purposeRaw');
      }
      try {
        intensity = MusicIntensityLabel.values.byName(intensityRaw);
      } on ArgumentError {
        throw CreativeDirectionException('Unknown intensity: $intensityRaw');
      }
      progression.add(
        CreativeIntensityStep(
          purpose: purpose,
          intensity: intensity,
          guidance: (step['guidance'] as String?)?.trim(),
        ),
      );
    }

    return PresentationCreativeDirection(
      narrationEmphasis: narrationEmphasis,
      pacingGuidance: pacingGuidance,
      pauses: _stringList(json['pauses']),
      intensityProgression: progression,
      musicPromptBrief: musicPromptBrief,
      transitionNotes: _stringList(json['transitionNotes']),
      providerLabel: (json['providerLabel'] as String?)?.trim(),
      modelLabel: (json['modelLabel'] as String?)?.trim(),
      processingVersion:
          (json['processingVersion'] as String?)?.trim().isNotEmpty == true
              ? (json['processingVersion'] as String).trim()
              : PresentationCreativeDirection.defaultProcessingVersion,
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const CreativeDirectionException(
        'Expected a JSON string array.',
      );
    }
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static void _rejectForbidden(Map<String, dynamic> json) {
    for (final key in json.keys) {
      if (forbiddenKeys.contains(key)) {
        throw CreativeDirectionException(
          'Creative-direction response included forbidden psychological '
          'field "$key".',
        );
      }
    }
  }
}
