import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_builder_session_snapshot_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryBuilderSessionSnapshotMapper', () {
    test('round-trips a complete session without domain events', () {
      final createdAt = DateTime.utc(2026, 9, 21, 10);
      final updatedAt = DateTime.utc(2026, 9, 21, 12);
      final responseCreated = DateTime.utc(2026, 9, 21, 11);
      final responseUpdated = DateTime.utc(2026, 9, 21, 11, 30);

      const responseA = StoryBuilderResponseId('resp-a');
      const responseB = StoryBuilderResponseId('resp-b');
      const responseC = StoryBuilderResponseId('resp-c');

      final session = StoryBuilderSession(
        id: const StoryBuilderSessionId('session-1'),
        heroId: const HeroId('hero-1'),
        status: StoryBuilderSessionStatus.paused,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent(
          purpose: StoryBuilderPurpose.shareALesson,
          themes: const [
            StoryBuilderTheme.courage,
            StoryBuilderTheme.perseverance,
          ],
        ),
        storyId: const StoryId('story-link'),
        createdAt: createdAt,
        updatedAt: updatedAt,
        prompts: [
          StoryBuilderPrompt(
            id: const StoryBuilderPromptId('sb.q.beginning'),
            text: 'What was happening?',
            ordinal: 0,
            narrativeRole: StoryBuilderNarrativeRole.beginning,
          ),
          StoryBuilderPrompt(
            id: const StoryBuilderPromptId('sb.q.challenge'),
            text: 'What were you facing?',
            ordinal: 1,
            narrativeRole: StoryBuilderNarrativeRole.challenge,
          ),
          StoryBuilderPrompt(
            id: const StoryBuilderPromptId('sb.q.importance'),
            text: 'Why did it matter?',
            ordinal: 2,
            narrativeRole: StoryBuilderNarrativeRole.importance,
            isOptional: true,
          ),
        ],
        responses: [
          StoryBuilderResponse(
            id: responseA,
            promptId: const StoryBuilderPromptId('sb.q.beginning'),
            ordinal: 0,
            text: 'Life was shifting.',
            createdAt: responseCreated,
          ),
          StoryBuilderResponse(
            id: responseB,
            promptId: const StoryBuilderPromptId('sb.q.challenge'),
            ordinal: 1,
            text: null,
            skipped: true,
            createdAt: responseCreated,
          ),
          StoryBuilderResponse(
            id: responseC,
            promptId: const StoryBuilderPromptId('sb.q.importance'),
            ordinal: 2,
            text: 'Edited importance.',
            createdAt: responseCreated,
            updatedAt: responseUpdated,
          ),
        ],
      );

      final json = StoryBuilderSessionSnapshotMapper.toJson(session);
      final restored = StoryBuilderSessionSnapshotMapper.fromJson(json);

      expect(restored.id, session.id);
      expect(restored.heroId, session.heroId);
      expect(restored.status, StoryBuilderSessionStatus.paused);
      expect(restored.mode, StoryBuilderMode.guided);
      expect(restored.intent.purpose, StoryBuilderPurpose.shareALesson);
      expect(restored.intent.themes, [
        StoryBuilderTheme.courage,
        StoryBuilderTheme.perseverance,
      ]);
      expect(restored.intent.themesUnsure, isFalse);
      expect(restored.storyId, const StoryId('story-link'));
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
      expect(restored.prompts, hasLength(3));
      expect(restored.responses, hasLength(3));

      expect(restored.responses[0].id, responseA);
      expect(restored.responses[0].text, 'Life was shifting.');
      expect(restored.responses[0].skipped, isFalse);

      expect(restored.responses[1].id, responseB);
      expect(restored.responses[1].skipped, isTrue);
      expect(restored.responses[1].text, isNull);

      expect(restored.responses[2].id, responseC);
      expect(restored.responses[2].text, 'Edited importance.');
      expect(restored.responses[2].updatedAt, responseUpdated);

      expect(restored.prompts[0].narrativeRole, StoryBuilderNarrativeRole.beginning);
      expect(restored.pullDomainEvents(), isEmpty);
    });

    test('round-trips a minimal empty session', () {
      final now = DateTime.utc(2026, 1, 1);
      final session = StoryBuilderSession(
        id: const StoryBuilderSessionId('minimal'),
        heroId: const HeroId('hero-min'),
        status: StoryBuilderSessionStatus.inProgress,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent.empty(),
        createdAt: now,
        updatedAt: now,
      );

      final restored = StoryBuilderSessionSnapshotMapper.fromJson(
        StoryBuilderSessionSnapshotMapper.toJson(session),
      );

      expect(restored.id.value, 'minimal');
      expect(restored.intent.purpose, isNull);
      expect(restored.intent.themes, isEmpty);
      expect(restored.intent.themesUnsure, isFalse);
      expect(restored.prompts, isEmpty);
      expect(restored.responses, isEmpty);
      expect(restored.storyId, isNull);
    });

    test('preserves purpose notSureYet and themesUnsure exactly', () {
      final now = DateTime.utc(2026, 2, 1);
      final session = StoryBuilderSession(
        id: const StoryBuilderSessionId('unsure'),
        heroId: const HeroId('hero-1'),
        status: StoryBuilderSessionStatus.inProgress,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent(
          purpose: StoryBuilderPurpose.notSureYet,
          themesUnsure: true,
        ),
        createdAt: now,
        updatedAt: now,
      );

      final restored = StoryBuilderSessionSnapshotMapper.fromJson(
        StoryBuilderSessionSnapshotMapper.toJson(session),
      );

      expect(restored.intent.purpose, StoryBuilderPurpose.notSureYet);
      expect(restored.intent.themesUnsure, isTrue);
      expect(restored.intent.themes, isEmpty);
      expect(restored.intent.isPurposeUnsure, isTrue);
    });

    test('preserves multiple themes without reordering', () {
      final now = DateTime.utc(2026, 3, 1);
      final session = StoryBuilderSession(
        id: const StoryBuilderSessionId('themes'),
        heroId: const HeroId('hero-1'),
        status: StoryBuilderSessionStatus.inProgress,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent(
          purpose: StoryBuilderPurpose.inspireSomeone,
          themes: const [
            StoryBuilderTheme.family,
            StoryBuilderTheme.service,
            StoryBuilderTheme.courage,
          ],
        ),
        createdAt: now,
        updatedAt: now,
      );

      final restored = StoryBuilderSessionSnapshotMapper.fromJson(
        StoryBuilderSessionSnapshotMapper.toJson(session),
      );

      expect(restored.intent.themes, [
        StoryBuilderTheme.family,
        StoryBuilderTheme.service,
        StoryBuilderTheme.courage,
      ]);
    });

    test('round-trips each lifecycle status', () {
      for (final status in StoryBuilderSessionStatus.values) {
        final now = DateTime.utc(2026, 4, 1);
        final session = StoryBuilderSession(
          id: StoryBuilderSessionId('status-${status.name}'),
          heroId: const HeroId('hero-1'),
          status: status,
          mode: StoryBuilderMode.guided,
          intent: StoryBuilderIntent.empty(),
          createdAt: now,
          updatedAt: now,
        );

        final restored = StoryBuilderSessionSnapshotMapper.fromJson(
          StoryBuilderSessionSnapshotMapper.toJson(session),
        );
        expect(restored.status, status);
      }
    });

    test('throws FormatException for malformed snapshot', () {
      expect(
        () => StoryBuilderSessionSnapshotMapper.fromJson(const {}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => StoryBuilderSessionSnapshotMapper.fromJson({
          'id': 'x',
          'heroId': 'h',
          'status': 'notARealStatus',
          'mode': 'guided',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => StoryBuilderSessionSnapshotMapper.fromJson({
          'id': 'x',
          'heroId': 'h',
          'status': 'inProgress',
          'mode': 'guided',
          'intent': 'not-a-map',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not include DeterministicStoryStructure in JSON', () {
      final now = DateTime.utc(2026, 5, 1);
      final session = StoryBuilderSession(
        id: const StoryBuilderSessionId('no-structure'),
        heroId: const HeroId('hero-1'),
        status: StoryBuilderSessionStatus.inProgress,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent.empty(),
        createdAt: now,
        updatedAt: now,
      );

      final json = StoryBuilderSessionSnapshotMapper.toJson(session);
      expect(json.containsKey('structure'), isFalse);
      expect(json.containsKey('deterministicStoryStructure'), isFalse);
      expect(json.containsKey('sections'), isFalse);
      expect(json.keys, containsAll([
        'id',
        'heroId',
        'status',
        'mode',
        'intent',
        'prompts',
        'responses',
        'createdAt',
        'updatedAt',
      ]));
    });
  });
}
