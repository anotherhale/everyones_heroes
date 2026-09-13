import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_heroes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_hero_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_hero_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_heroes_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/experience_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_experience_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_experience_view_model.dart';

final discoverableHeroesProvider =
    FutureProvider.autoDispose<DiscoverHeroesResponse>((ref) async {
      final result = await ref
          .watch(discoverHeroesUseCaseProvider)
          .execute(const DiscoverHeroesRequest());
      if (result is Failure<DiscoverHeroesResponse>) {
        throw Exception(result.error);
      }
      return (result as Success<DiscoverHeroesResponse>).value;
    });

final discoverableStoriesProvider =
    FutureProvider.autoDispose<DiscoverStoriesResponse>((ref) async {
      final result = await ref
          .watch(discoverStoriesUseCaseProvider)
          .execute(const DiscoverStoriesRequest());
      if (result is Failure<DiscoverStoriesResponse>) {
        throw Exception(result.error);
      }
      return (result as Success<DiscoverStoriesResponse>).value;
    });

final heroExperienceProvider = FutureProvider.autoDispose
    .family<HeroExperienceViewModel, String>((ref, heroIdValue) async {
      final result = await ref
          .watch(getHeroExperienceUseCaseProvider)
          .execute(GetHeroExperienceRequest(heroId: HeroId(heroIdValue)));
      if (result is Failure<HeroExperienceDetail>) {
        throw Exception(result.error);
      }
      return HeroExperienceViewModel.fromDetail(
        (result as Success<HeroExperienceDetail>).value,
      );
    });

final heroStoriesProvider = FutureProvider.autoDispose
    .family<DiscoverStoriesResponse, String>((ref, heroIdValue) async {
      final result = await ref
          .watch(listHeroStoriesUseCaseProvider)
          .execute(ListHeroStoriesRequest(heroId: HeroId(heroIdValue)));
      if (result is Failure<DiscoverStoriesResponse>) {
        throw Exception(result.error);
      }
      return (result as Success<DiscoverStoriesResponse>).value;
    });

final storyExperienceProvider = FutureProvider.autoDispose
    .family<StoryExperienceViewModel, String>((ref, storyIdValue) async {
      final result = await ref
          .watch(getStoryExperienceUseCaseProvider)
          .execute(GetStoryExperienceRequest(storyId: StoryId(storyIdValue)));
      if (result is Failure<StoryExperienceDetail>) {
        throw Exception(result.error);
      }
      return StoryExperienceViewModel.fromDetail(
        (result as Success<StoryExperienceDetail>).value,
      );
    });
