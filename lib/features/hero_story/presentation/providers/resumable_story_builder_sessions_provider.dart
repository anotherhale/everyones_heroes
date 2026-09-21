import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_resumable_story_builder_sessions_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_builder_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';

/// Resumable (in-progress / paused) Story Builder sessions for the active Hero.
final resumableStoryBuilderSessionsProvider =
    FutureProvider.autoDispose<List<StoryBuilderSession>>((ref) async {
      final hero = await ref.watch(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .watch(listResumableStoryBuilderSessionsUseCaseProvider)
          .execute(
            ListResumableStoryBuilderSessionsRequest(heroId: hero.id),
          );
      if (result is Failure) {
        throw StateError((result as Failure).error);
      }
      return (result as Success<List<StoryBuilderSession>>).value;
    });
