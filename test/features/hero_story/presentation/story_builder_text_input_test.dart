import 'package:everyonesheroes/app/presentation/theme/app_theme.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Presentation regression for Story Builder response editing.
///
/// Widget tests cannot faithfully validate iOS QuickType / IME composition.
/// Those must be verified on a physical iPhone (see test file header comment
/// in the suite description below).
void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;
  late ActiveLocalHeroStore heroStore;
  late HeroId heroId;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    heroId = HeroId.generate();
    await heroes.save(
      hs.Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Input Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
    heroStore = ActiveLocalHeroStore();
    await heroStore.setActive(heroId);
  });

  Widget buildApp({
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode themeMode = ThemeMode.light,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return ProviderScope(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
        activeLocalHeroStoreProvider.overrideWithValue(heroStore),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          darkTheme: darkTheme ?? AppTheme.dark(),
          themeMode: themeMode,
          home: const StoryBuilderScreen(),
        ),
      ),
    );
  }

  Future<void> settleOnQuestion(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('story-builder-response-field')),
      findsOneWidget,
    );
  }

  group('Story Builder response TextField', () {
    testWidgets('renders hint and accepts multiline typed text', (tester) async {
      await settleOnQuestion(tester);

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('story-builder-response-field')),
      );
      expect(field.decoration?.hintText, 'Write in your own words…');
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isTrue);
      expect(field.expands, isFalse);
      expect(field.minLines, 6);
      expect(field.maxLines, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('story-builder-response-field')),
        'I remember when everything changed.\n\nI kept going.',
      );
      await tester.pump();

      expect(
        find.text('I remember when everything changed.\n\nI kept going.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'controller identity stays stable across Riverpod draft updates',
      (tester) async {
        await settleOnQuestion(tester);

        final before = tester.widget<TextField>(
          find.byKey(const ValueKey('story-builder-response-field')),
        );
        final controller = before.controller!;
        expect(controller, isNotNull);

        await tester.enterText(
          find.byKey(const ValueKey('story-builder-response-field')),
          'I remember when',
        );
        await tester.pump();

        // Trigger additional provider-driven rebuilds without changing prompt.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(StoryBuilderScreen)),
        );
        container.read(storyBuilderControllerProvider.notifier).updateDraft(
              'I remember when',
            );
        await tester.pump();
        container.read(storyBuilderControllerProvider.notifier).updateDraft(
              'I remember when I was young',
            );
        // Simulate external rebuild pressure; controller text is source of truth
        // for IME — do not expect listen to overwrite mid-edit from draft alone.
        await tester.pump();

        final after = tester.widget<TextField>(
          find.byKey(const ValueKey('story-builder-response-field')),
        );
        expect(identical(after.controller, controller), isTrue);
        // Typing path owns the controller; provider mirror must not replace it.
        expect(after.controller!.text, 'I remember when');
      },
    );

    testWidgets(
      'provider draft updates from typing do not recreate the controller',
      (tester) async {
        await settleOnQuestion(tester);
        final controllers = <TextEditingController>[];

        for (final chunk in ['I', 'I ', 'I r', 'I remember when']) {
          await tester.enterText(
            find.byKey(const ValueKey('story-builder-response-field')),
            chunk,
          );
          await tester.pump();
          final field = tester.widget<TextField>(
            find.byKey(const ValueKey('story-builder-response-field')),
          );
          controllers.add(field.controller!);
        }

        for (var i = 1; i < controllers.length; i++) {
          expect(
            identical(controllers[i], controllers.first),
            isTrue,
            reason: 'controller recreated at step $i',
          );
        }
        expect(controllers.last.text, 'I remember when');
      },
    );

    testWidgets('restores existing answer when navigating back to a prompt', (
      tester,
    ) async {
      await settleOnQuestion(tester);

      const firstAnswer = 'I was scared and did not know what to do.';
      await tester.enterText(
        find.byKey(const ValueKey('story-builder-response-field')),
        firstAnswer,
      );
      await tester.tap(find.byKey(const ValueKey('story-builder-continue')));
      await tester.pumpAndSettle();

      expect(find.text('What were you facing?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('story-builder-back')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('story-builder-response-field')),
      );
      expect(field.controller!.text, firstAnswer);
      expect(find.text(firstAnswer), findsOneWidget);
    });

    testWidgets('dark theme uses dark filled input and light text', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(
        tester.element(find.byKey(const ValueKey('story-builder-response-field'))),
      );
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('story-builder-response-field')),
      );

      expect(theme.brightness, Brightness.dark);
      expect(
        theme.inputDecorationTheme.fillColor,
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(field.style?.color, theme.colorScheme.onSurface);
      expect(field.cursorColor, theme.colorScheme.primary);
      expect(
        field.style?.color,
        isNot(equals(theme.inputDecorationTheme.fillColor)),
      );
    });

    testWidgets('light theme uses light filled input and dark text', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(
        tester.element(find.byKey(const ValueKey('story-builder-response-field'))),
      );
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('story-builder-response-field')),
      );

      expect(theme.brightness, Brightness.light);
      expect(
        theme.inputDecorationTheme.fillColor,
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(field.style?.color, theme.colorScheme.onSurface);
      expect(
        field.style?.color,
        isNot(equals(theme.inputDecorationTheme.fillColor)),
      );
    });

    testWidgets('large text scale keeps layout usable without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(textScaler: const TextScaler.linear(2.0)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('story-builder-prompt')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('story-builder-response-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-builder-continue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-builder-question-scroll')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('story-builder-response-field')),
        'Longer accessibility response that must remain visible.',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('response field can take focus', (tester) async {
      await settleOnQuestion(tester);
      final fieldFinder =
          find.byKey(const ValueKey('story-builder-response-field'));
      await tester.tap(fieldFinder);
      await tester.pump();

      final field = tester.widget<TextField>(fieldFinder);
      expect(field.focusNode!.hasFocus, isTrue);
    });
  });
}
