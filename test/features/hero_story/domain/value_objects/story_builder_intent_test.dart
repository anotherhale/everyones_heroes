import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryBuilderIntent vocabulary', () {
    test('purpose and themes are independent dimensions', () {
      final intent = StoryBuilderIntent(
        purpose: StoryBuilderPurpose.inspireSomeone,
        themes: const [
          StoryBuilderTheme.overcomingAdversity,
          StoryBuilderTheme.courage,
        ],
      );

      final purposeOnly = intent.withPurpose(
        StoryBuilderPurpose.encourageSomeone,
      );
      expect(purposeOnly.purpose, StoryBuilderPurpose.encourageSomeone);
      expect(purposeOnly.themes, intent.themes);

      final themesOnly = intent.withThemes(
        themes: const [StoryBuilderTheme.secondChances],
      );
      expect(themesOnly.purpose, intent.purpose);
      expect(themesOnly.themes, [StoryBuilderTheme.secondChances]);
    });

    test('rejects themesUnsure combined with selected themes', () {
      expect(
        () => StoryBuilderIntent(
          themes: const [StoryBuilderTheme.love],
          themesUnsure: true,
        ),
        throwsArgumentError,
      );
    });

    test('dedupes themes while preserving first-seen order', () {
      final intent = StoryBuilderIntent(
        themes: const [
          StoryBuilderTheme.family,
          StoryBuilderTheme.courage,
          StoryBuilderTheme.family,
        ],
      );
      expect(intent.themes, [
        StoryBuilderTheme.family,
        StoryBuilderTheme.courage,
      ]);
    });

    test('empty intents compare equal', () {
      expect(StoryBuilderIntent.empty(), StoryBuilderIntent());
    });
  });

  group('StoryBuilderSession purpose/theme behavior', () {
    StoryBuilderSession createSession() {
      return StoryBuilderSession.create(
        id: StoryBuilderSessionId.generate(),
        heroId: HeroId.generate(),
      );
    }

    test('setPurpose and setThemes update independently', () {
      final session = createSession()..pullDomainEvents();
      session.setPurpose(StoryBuilderPurpose.shareALesson);
      session.setThemes(
        themes: const [
          StoryBuilderTheme.transformation,
          StoryBuilderTheme.discovery,
        ],
      );

      expect(session.intent.purpose, StoryBuilderPurpose.shareALesson);
      expect(session.intent.themes, [
        StoryBuilderTheme.transformation,
        StoryBuilderTheme.discovery,
      ]);

      session.setPurpose(StoryBuilderPurpose.honorSomeone);
      expect(session.intent.purpose, StoryBuilderPurpose.honorSomeone);
      expect(session.intent.themes, [
        StoryBuilderTheme.transformation,
        StoryBuilderTheme.discovery,
      ]);

      session.setThemes(themes: const [StoryBuilderTheme.sacrifice]);
      expect(session.intent.purpose, StoryBuilderPurpose.honorSomeone);
      expect(session.intent.themes, [StoryBuilderTheme.sacrifice]);
    });

    test('purpose and themes remain editable while paused', () {
      final session = createSession()..pullDomainEvents();
      session.pause();
      session.setPurpose(StoryBuilderPurpose.preserveAMemory);
      session.setThemes(themesUnsure: true);

      expect(session.status, StoryBuilderSessionStatus.paused);
      expect(session.intent.purpose, StoryBuilderPurpose.preserveAMemory);
      expect(session.intent.themesUnsure, isTrue);
    });

    test('completed and abandoned sessions reject intent changes', () {
      final completed = createSession()..pullDomainEvents();
      completed.complete();
      expect(
        () => completed.setPurpose(StoryBuilderPurpose.inspireSomeone),
        throwsStateError,
      );

      final abandoned = createSession()..pullDomainEvents();
      abandoned.abandon();
      expect(
        () => abandoned.setThemes(themes: const [StoryBuilderTheme.loss]),
        throwsStateError,
      );
    });

    test('clearing purpose does not clear themes', () {
      final session = createSession()..pullDomainEvents();
      session.setPurpose(StoryBuilderPurpose.simplyTellMyStory);
      session.setThemes(themes: const [StoryBuilderTheme.leadership]);
      session.setPurpose(null);

      expect(session.intent.purpose, isNull);
      expect(session.intent.themes, [StoryBuilderTheme.leadership]);
    });
  });
}
