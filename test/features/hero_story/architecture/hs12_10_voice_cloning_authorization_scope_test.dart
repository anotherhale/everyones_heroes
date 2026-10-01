import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.12.10 architecture checks for Voice Cloning Authorization Scope.
void main() {
  test('VoiceCloningAuthorizationScope is modeled with perStory default', () {
    final enumSource = File(
      'lib/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart',
    ).readAsStringSync();
    final aggregate = File(
      'lib/features/hero_story/domain/aggregates/voice_profile.dart',
    ).readAsStringSync();

    expect(enumSource.contains('perStory'), isTrue);
    expect(enumSource.contains('perProfile'), isTrue);
    expect(
      aggregate.contains('VoiceCloningAuthorizationScope.perStory'),
      isTrue,
    );
    expect(
      aggregate.contains('setCloningAuthorizationScope'),
      isTrue,
    );
  });

  test('scope and cloning authorization remain separate concepts', () {
    final aggregate = File(
      'lib/features/hero_story/domain/aggregates/voice_profile.dart',
    ).readAsStringSync();
    final auth = File(
      'lib/features/hero_story/domain/value_objects/voice_profile_authorization.dart',
    ).readAsStringSync();

    expect(aggregate.contains('cloningAuthorizationScope'), isTrue);
    expect(auth.contains('cloningAuthorizedAt'), isTrue);
    // Must not collapse into a single boolean.
    expect(aggregate.contains('bool voiceApproved'), isFalse);
    expect(auth.contains('final bool voiceApproved'), isFalse);
  });

  test('effective authorization policy is centralized in domain', () {
    final policy = File(
      'lib/features/hero_story/domain/services/voice_cloning_authorization_policy.dart',
    ).readAsStringSync();

    expect(policy.contains('class VoiceCloningAuthorizationPolicy'), isTrue);
    expect(policy.contains('EffectiveVoiceCloningAuthorization'), isTrue);
    expect(policy.contains('package:flutter'), isFalse);
    expect(policy.contains('riverpod'), isFalse);
    expect(policy.contains('ElevenLabs'), isFalse);
    expect(policy.contains('OpenAI'), isFalse);
    expect(policy.contains('Qwen'), isFalse);
  });

  test('presentation does not calculate effective cloning authorization', () {
    final presentationDir = Directory(
      'lib/features/hero_story/presentation',
    );
    final dartFiles = presentationDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source.contains('VoiceCloningAuthorizationPolicy'),
        isFalse,
        reason: '${file.path} must not evaluate cloning policy',
      );
      expect(
        source.contains('EffectiveVoiceCloningAuthorization'),
        isFalse,
        reason: '${file.path} must not own effective cloning authorization',
      );
    }
  });

  test('VoiceProfile remains Hero-scoped and provider-free', () {
    final aggregate = File(
      'lib/features/hero_story/domain/aggregates/voice_profile.dart',
    ).readAsStringSync();

    expect(aggregate.contains('HeroId ownerHeroId'), isTrue);
    expect(aggregate.contains('providerVoiceId'), isFalse);
    expect(aggregate.contains('ElevenLabs'), isFalse);
    expect(aggregate.contains('OpenAI'), isFalse);
    expect(aggregate.contains('Qwen'), isFalse);
    expect(aggregate.contains('Uint8List'), isFalse);
  });

  test('Story consent cloning fields remain provider-free', () {
    final consent = File(
      'lib/features/hero_story/domain/value_objects/story_consent.dart',
    ).readAsStringSync();
    final story = File(
      'lib/features/hero_story/domain/aggregates/story.dart',
    ).readAsStringSync();

    expect(consent.contains('voiceCloningAuthorizedAt'), isTrue);
    expect(consent.contains('voiceCloningDeniedAt'), isTrue);
    expect(consent.contains('voiceRenderingApprovedAt'), isTrue);
    expect(consent.contains('providerVoiceId'), isFalse);
    expect(consent.contains('ElevenLabs'), isFalse);
    expect(story.contains('package:http'), isFalse);
    expect(story.contains('ElevenLabs'), isFalse);
  });

  test('VoiceRenderingPort remains unchanged (no cloning enablement)', () {
    final port = File(
      'lib/features/hero_story/domain/services/voice_rendering_port.dart',
    ).readAsStringSync();
    final useCase = File(
      'lib/features/hero_story/application/use_cases/render_story_voice_use_case.dart',
    ).readAsStringSync();
    final profilePort = File(
      'lib/features/hero_story/domain/services/voice_profile_port.dart',
    ).readAsStringSync();

    expect(port.contains('abstract interface class VoiceRenderingPort'), isTrue);
    expect(port.contains('VoiceCloningAuthorizationScope'), isFalse);
    expect(
      useCase.contains('is not supported') ||
          useCase.contains('Only syntheticNarration'),
      isTrue,
    );
    expect(profilePort.contains('abstract interface class VoiceProfilePort'), isTrue);
    expect(profilePort.contains('enroll('), isTrue);
  });

  test('synthetic narration remains valid without VoiceProfile cloning', () {
    final rendering = StoryVoiceRendering(
      id: StoryVoiceRenderingId.generate(),
      storyId: StoryId.generate(),
      experiencePlanId: StoryExperiencePlanId.generate(),
      experiencePlanProcessingVersion: 'v1',
      sourceRepresentationId: StoryRepresentationId.generate(),
      language: LanguageCode('en'),
      renderingMode: VoiceRenderingMode.syntheticNarration,
      mediaReference: MediaReference('media://synthetic-audio'),
      contentType: 'audio/mpeg',
      byteLength: 128,
      createdAt: DateTime.utc(2026, 10, 1),
    );

    expect(rendering.isSyntheticNarration, isTrue);

    // HS.12.10 still defers optional voiceProfileId on StoryVoiceRendering.
    final source = File(
      'lib/features/hero_story/domain/value_objects/story_voice_rendering.dart',
    ).readAsStringSync();
    expect(source.contains('voiceProfileId'), isFalse);
  });

  test('provider identifiers cannot enter domain voice cloning types', () {
    final files = [
      'lib/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart',
      'lib/features/hero_story/domain/services/voice_cloning_authorization_policy.dart',
      'lib/features/hero_story/domain/value_objects/effective_voice_cloning_authorization.dart',
      'lib/features/hero_story/domain/aggregates/voice_profile.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source.contains('ElevenLabs'), isFalse, reason: path);
      expect(source.contains('providerVoiceId'), isFalse, reason: path);
      expect(source.contains('openai'), isFalse, reason: path);
      expect(source.contains('Qwen3'), isFalse, reason: path);
      expect(source.contains('CosyVoice'), isFalse, reason: path);
    }

    // IDs remain EH-owned.
    final profileId = VoiceProfileId.generate();
    final heroId = HeroId.generate();
    expect(profileId.runtimeType, isNot(heroId.runtimeType));
  });

  test('default scope enum value is perStory', () {
    expect(
      VoiceCloningAuthorizationScope.perStory,
      VoiceCloningAuthorizationScope.values.first,
    );
  });

  test('HS.12.10 documentation exists', () {
    final doc = File(
      'docs/architecture/HS.12.10-Voice-Cloning-Authorization-Scope.md',
    );
    expect(doc.existsSync(), isTrue);
    final text = doc.readAsStringSync();
    expect(text.contains('perStory'), isTrue);
    expect(text.contains('perProfile'), isTrue);
  });
}
