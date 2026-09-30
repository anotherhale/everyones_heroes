import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// HS.12.8 architecture boundary checks for Voice Identity & Cloning.
///
/// These tests lock the spike decisions without implementing production
/// cloning, enrollment persistence, or provider adapters (HS-ADR-078).
void main() {
  test('VoiceProfileId exists and is distinct from StoryVoiceRenderingId', () {
    final idsDir = Directory('lib/core/ids');
    final names = idsDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();

    expect(names, contains('voice_profile_id.dart'));
    expect(names, contains('story_voice_rendering_id.dart'));

    final voiceProfileId = File('lib/core/ids/voice_profile_id.dart')
        .readAsStringSync();
    expect(voiceProfileId.contains('class VoiceProfileId'), isTrue);
    expect(
      voiceProfileId.contains('StoryVoiceRendering'),
      isTrue,
      reason: 'Docs must keep identity ≠ artifact explicit',
    );
  });

  test('VoiceProfilePort is separate from VoiceRenderingPort', () {
    final services = Directory('lib/features/hero_story/domain/services');
    final names = services
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();

    expect(names, contains('voice_profile_port.dart'));
    expect(names, contains('voice_rendering_port.dart'));

    final profilePort =
        File('lib/features/hero_story/domain/services/voice_profile_port.dart')
            .readAsStringSync();
    final renderingPort =
        File(
          'lib/features/hero_story/domain/services/voice_rendering_port.dart',
        ).readAsStringSync();

    expect(profilePort.contains('abstract interface class VoiceProfilePort'), isTrue);
    expect(profilePort.contains('enroll('), isTrue);
    expect(profilePort.contains('revoke('), isTrue);
    expect(profilePort.contains('delete('), isTrue);

    // Enrollment must not become a narration render method.
    expect(profilePort.contains('Future<VoiceRenderingDraft> render'), isFalse);
    expect(renderingPort.contains('VoiceProfilePort'), isFalse);

    // Provider-specific identity must not appear as domain fields.
    for (final forbidden in [
      'elevenLabs',
      'ElevenLabs',
      'openaiVoiceId',
      'providerVoiceId',
      'OPENAI_API_KEY',
      'qwenSpeaker',
    ]) {
      expect(
        profilePort.contains(forbidden),
        isFalse,
        reason: 'VoiceProfilePort must not expose $forbidden',
      );
      expect(
        renderingPort.contains(forbidden),
        isFalse,
        reason: 'VoiceRenderingPort must not expose $forbidden',
      );
    }
  });

  test('domain VoiceProfilePort does not import proxy, HTTP, or vendor SDKs', () {
    final file = File(
      'lib/features/hero_story/domain/services/voice_profile_port.dart',
    );
    final content = file.readAsStringSync();

    final forbidden = [
      "import 'package:http",
      'import "package:http',
      "import 'package:openai",
      'services/ai_proxy',
      'TtsProvider',
      'OpenAi',
      'ElevenLabs',
    ];

    for (final needle in forbidden) {
      expect(
        content.contains(needle),
        isFalse,
        reason: 'VoiceProfilePort must not contain: $needle',
      );
    }
  });

  test('StoryVoiceRendering remains a derived artifact without VoiceProfile collapse',
      () {
    final rendering = File(
      'lib/features/hero_story/domain/value_objects/story_voice_rendering.dart',
    ).readAsStringSync();

    expect(rendering.contains('class StoryVoiceRendering'), isTrue);
    expect(
      rendering.contains('VoiceProfile'),
      isTrue,
      reason: 'Comments should keep cloning/profile out of synthetic contract',
    );
    // HS.12.8 must not collapse VoiceProfile into the rendering VO.
    expect(rendering.contains('class VoiceProfile'), isFalse);
    expect(rendering.contains('providerVoiceId'), isFalse);
  });

  test('voiceClone mode remains defined but not enabled by HS.12.8 production path',
      () {
    final modeFile = File(
      'lib/features/hero_story/domain/enums/voice_rendering_mode.dart',
    ).readAsStringSync();
    expect(modeFile.contains('voiceClone'), isTrue);
    expect(modeFile.contains('syntheticNarration'), isTrue);

    final useCase = File(
      'lib/features/hero_story/application/use_cases/render_story_voice_use_case.dart',
    ).readAsStringSync();
    expect(
      useCase.contains('syntheticNarration'),
      isTrue,
    );
    expect(
      useCase.contains('is not supported') ||
          useCase.contains('Only syntheticNarration'),
      isTrue,
      reason: 'RenderStoryVoiceUseCase must still reject non-synthetic modes',
    );
  });

  test('HS.12.8 ADR and spike report exist', () {
    expect(
      File(
        'docs/architecture/HS-ADR-078-Voice-Identity-and-Cloning-Boundary.md',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'docs/architecture/HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md',
      ).existsSync(),
      isTrue,
    );

    final decisions =
        File('docs/architecture/architecture-decisions.md').readAsStringSync();
    expect(decisions.contains('HS-ADR-078'), isTrue);
  });
}
