import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_detail_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_list_item_model.dart';

/// Active owner's My Stories list (excludes archived by default).
final ownedStoriesProvider =
    FutureProvider.autoDispose<List<OwnedStoryListItemModel>>((ref) async {
      final hero = await ref.watch(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .watch(listHeroOwnedStoriesUseCaseProvider)
          .execute(ListHeroOwnedStoriesRequest(heroId: hero.id));
      if (result is Failure<List<OwnedStorySummary>>) {
        throw Exception(result.error);
      }
      final summaries = (result as Success<List<OwnedStorySummary>>).value;
      return summaries
          .map(OwnedStoryListItemModel.fromSummary)
          .toList(growable: false);
    });

/// Owner Story detail (private drafts included).
final ownedStoryDetailProvider = FutureProvider.autoDispose
    .family<OwnedStoryDetailViewModel, String>((ref, storyIdValue) async {
      final hero = await ref.watch(ensureActiveLocalHeroProvider.future);
      final result = await ref
          .watch(getOwnedStoryDetailUseCaseProvider)
          .execute(
            GetOwnedStoryDetailRequest(
              storyId: StoryId(storyIdValue),
              ownerHeroId: hero.id,
            ),
          );
      if (result is Failure<OwnedStoryDetail>) {
        throw Exception(result.error);
      }
      return OwnedStoryDetailViewModel.fromDetail(
        (result as Success<OwnedStoryDetail>).value,
      );
    });
