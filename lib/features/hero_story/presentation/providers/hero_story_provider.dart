import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_story_view_data.dart';

/// Persisted Hero Story content for [HeroStoryScreen].
///
/// The title is the stored Story title. This provider does not invent one.
final heroStoryProvider = FutureProvider.autoDispose
    .family<HeroStoryViewData, String>((ref, storyIdValue) async {
      final owner = await ref.watch(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .watch(getOwnedStoryDetailUseCaseProvider)
          .execute(
            GetOwnedStoryDetailRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: owner.id,
            ),
          );
      if (result is Failure<OwnedStoryDetail>) {
        throw Exception(result.error);
      }
      final detail = (result as Success<OwnedStoryDetail>).value;
      final hero = await ref
          .watch(heroRepositoryProvider)
          .findById(detail.heroId);
      final heroName = hero?.profile.displayName ?? owner.profile.displayName;
      return HeroStoryViewData.fromHeroAndTitle(
        heroName: heroName,
        title: detail.title,
        originalRecordingId: detail.primaryOriginalAudioId,
      );
    });
