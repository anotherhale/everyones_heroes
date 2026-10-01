import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.12.9 architecture checks for Voice Profile Foundation.
void main() {
  test('VoiceProfile aggregate exists and is Hero-scoped in source', () {
    final aggregate = File(
      'lib/features/hero_story/domain/aggregates/voice_profile.dart',
    ).readAsStringSync();

    expect(aggregate.contains('class VoiceProfile'), isTrue);
    expect(aggregate.contains('HeroId ownerHeroId'), isTrue);
    expect(aggregate.contains('providerVoiceId'), isFalse);
    expect(aggregate.contains('OpenAI'), isFalse);
    expect(aggregate.contains('ElevenLabs'), isFalse);
    expect(aggregate.contains('Qwen'), isFalse);
    expect(aggregate.contains('Uint8List'), isFalse);
  });

  test('VoiceProfileAuthorization keeps four independent gates', () {
    final auth = File(
      'lib/features/hero_story/domain/value_objects/voice_profile_authorization.dart',
    ).readAsStringSync();

    expect(auth.contains('enrollmentAuthorizedAt'), isTrue);
    expect(auth.contains('cloningAuthorizedAt'), isTrue);
    expect(auth.contains('storyUseAuthorizedAt'), isTrue);
    expect(auth.contains('publicationAuthorizedAt'), isTrue);
    expect(auth.contains('voiceApproved'), isFalse);
    expect(auth.contains('voiceRenderingApprovedAt'), isTrue);
  });

  test('VoiceProfilePort remains separate from VoiceRenderingPort', () {
    final profilePort =
        File('lib/features/hero_story/domain/services/voice_profile_port.dart')
            .readAsStringSync();
    final renderingPort = File(
      'lib/features/hero_story/domain/services/voice_rendering_port.dart',
    ).readAsStringSync();

    expect(profilePort.contains('abstract interface class VoiceProfilePort'), isTrue);
    expect(profilePort.contains('enroll('), isTrue);
    expect(profilePort.contains('revoke('), isTrue);
    expect(profilePort.contains('delete('), isTrue);
    expect(profilePort.contains('Future<VoiceRenderingDraft> render'), isFalse);
    expect(renderingPort.contains('VoiceProfilePort'), isFalse);
  });

  test('InMemoryVoiceProfileAdapter is synthetic, not a provider SDK', () {
    final adapter = File(
      'lib/features/hero_story/infrastructure/ai/in_memory_voice_profile_adapter.dart',
    ).readAsStringSync();

    expect(adapter.contains('class InMemoryVoiceProfileAdapter'), isTrue);
    expect(adapter.contains('synthetic'), isTrue);
    expect(adapter.contains('openai'), isFalse);
    expect(adapter.contains('elevenlabs'), isFalse);
    expect(adapter.contains('package:http'), isFalse);
  });

  test('StoryVoiceRendering remains valid without VoiceProfile', () {
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
    expect(rendering.renderingMode, VoiceRenderingMode.syntheticNarration);

    // HS.12.9 defers optional voiceProfileId on StoryVoiceRendering to avoid
    // persistence migration before voiceClone is enabled.
    final source = File(
      'lib/features/hero_story/domain/value_objects/story_voice_rendering.dart',
    ).readAsStringSync();
    expect(source.contains('voiceProfileId'), isFalse);
    expect(source.contains('class VoiceProfile'), isFalse);
  });

  test('VoiceProfileId remains distinct from provider and rendering ids', () {
    final profileId = VoiceProfileId.generate();
    final renderingId = StoryVoiceRenderingId.generate();
    final heroId = HeroId.generate();

    expect(profileId.value, isNot(renderingId.value));
    expect(profileId.runtimeType, isNot(renderingId.runtimeType));
    expect(profileId.runtimeType, isNot(heroId.runtimeType));
  });

  test('voiceClone rejection path remains in RenderStoryVoiceUseCase', () {
    final useCase = File(
      'lib/features/hero_story/application/use_cases/render_story_voice_use_case.dart',
    ).readAsStringSync();
    expect(
      useCase.contains('is not supported') ||
          useCase.contains('Only syntheticNarration'),
      isTrue,
    );
  });

  test('HS.12.9 documentation status is recorded', () {
    final plan = File(
      'docs/architecture/Voice-Synthesis-Voice-Cloning-Implementation-Plan.md',
    ).readAsStringSync();
    expect(plan.contains('HS.12.9'), isTrue);
    expect(
      plan.contains('Voice Profile Foundation'),
      isTrue,
    );
  });
}
