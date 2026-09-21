import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_purpose_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_themes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_purpose_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_themes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late SetStoryBuilderPurposeUseCase setPurpose;
  late SetStoryBuilderThemesUseCase setThemes;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    start = StartStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    setPurpose = SetStoryBuilderPurposeUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    setThemes = SetStoryBuilderThemesUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
  });

  test('purpose and themes persist independently through save/load', () async {
    final sessionId = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: HeroId.generate(),
      ),
    );

    final purposeResult = await setPurpose.execute(
      SetStoryBuilderPurposeRequest(
        sessionId: sessionId,
        purpose: StoryBuilderPurpose.helpSomeoneFacingSomethingSimilar,
      ),
    );
    expect(purposeResult, isA<Success<StoryBuilderSession>>());

    final themesResult = await setThemes.execute(
      SetStoryBuilderThemesRequest(
        sessionId: sessionId,
        themes: const [
          StoryBuilderTheme.overcomingAdversity,
          StoryBuilderTheme.secondChances,
        ],
      ),
    );
    expect(themesResult, isA<Success<StoryBuilderSession>>());

    final loaded = await repository.findById(sessionId);
    expect(
      loaded!.intent.purpose,
      StoryBuilderPurpose.helpSomeoneFacingSomethingSimilar,
    );
    expect(loaded.intent.themes, [
      StoryBuilderTheme.overcomingAdversity,
      StoryBuilderTheme.secondChances,
    ]);

    await setPurpose.execute(
      SetStoryBuilderPurposeRequest(
        sessionId: sessionId,
        purpose: StoryBuilderPurpose.inspireSomeone,
      ),
    );
    final afterPurposeChange = await repository.findById(sessionId);
    expect(
      afterPurposeChange!.intent.purpose,
      StoryBuilderPurpose.inspireSomeone,
    );
    expect(afterPurposeChange.intent.themes, [
      StoryBuilderTheme.overcomingAdversity,
      StoryBuilderTheme.secondChances,
    ]);
  });

  test('invalid themesUnsure combination returns Failure', () async {
    final sessionId = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: HeroId.generate(),
      ),
    );

    final result = await setThemes.execute(
      SetStoryBuilderThemesRequest(
        sessionId: sessionId,
        themes: const [StoryBuilderTheme.courage],
        themesUnsure: true,
      ),
    );
    expect(result, isA<Failure>());
  });
}
