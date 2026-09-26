import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_my_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_hero_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/my_hero_profile_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_experience_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owner_hero_discoverability_providers.dart';

/// Active owner's Hero profile without discoverability gate (HP.1).
///
/// Resolves: ActiveLocalHeroStore → HeroId → GetMyHeroUseCase → Hero.
final myHeroProfileProvider =
    FutureProvider.autoDispose<MyHeroProfileViewModel>((ref) async {
  final active = await ref.watch(ensureActiveLocalHeroProvider.future);
  final result = await ref.read(getMyHeroUseCaseProvider).execute(
        GetMyHeroRequest(heroId: active.id),
      );
  if (result is Failure<Hero>) {
    throw Exception(result.error);
  }
  return MyHeroProfileViewModel.fromHero((result as Success<Hero>).value);
});

/// UI action state for saving My Hero Profile.
final class MyHeroProfileActionState {
  const MyHeroProfileActionState({
    this.isBusy = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  final bool isBusy;
  final String? errorMessage;
  final bool savedSuccessfully;

  MyHeroProfileActionState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool? savedSuccessfully,
    bool clearError = false,
    bool clearSaved = false,
  }) {
    return MyHeroProfileActionState(
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully:
          clearSaved ? false : (savedSuccessfully ?? this.savedSuccessfully),
    );
  }
}

final myHeroProfileControllerProvider = NotifierProvider.autoDispose<
    MyHeroProfileController, MyHeroProfileActionState>(
  MyHeroProfileController.new,
);

final class MyHeroProfileController extends Notifier<MyHeroProfileActionState> {
  @override
  MyHeroProfileActionState build() {
    return const MyHeroProfileActionState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSavedFlag() {
    state = state.copyWith(clearSaved: true);
  }

  /// Saves profile fields through [UpdateHeroProfileUseCase].
  ///
  /// Does not change discoverability. Private Heroes remain editable.
  Future<bool> save({
    required String displayName,
    String? biography,
    Iterable<String>? experienceAreas,
    Iterable<LanguageCode>? languages,
    String? geographicContext,
  }) async {
    if (state.isBusy) {
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true, clearSaved: true);

    try {
      final HeroProfile profile;
      try {
        profile = HeroProfile(
          displayName: displayName,
          biography: biography,
          experienceAreas: experienceAreas,
          languages: languages,
          geographicContext: geographicContext,
        );
      } on ArgumentError catch (e) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: e.message?.toString() ?? e.toString(),
        );
        return false;
      }

      final active = await ref.read(ensureActiveLocalHeroProvider.future);
      final result =
          await ref.read(updateHeroProfileUseCaseProvider).execute(
                UpdateHeroProfileRequest(
                  heroId: active.id,
                  profile: profile,
                ),
              );

      if (result is Failure<Hero>) {
        state = state.copyWith(isBusy: false, errorMessage: result.error);
        return false;
      }

      final heroIdValue = active.id.value;

      // Invalidate only after persistence succeeds — never optimistic.
      ref.invalidate(ensureActiveLocalHeroProvider);
      ref.invalidate(myHeroProfileProvider);
      ref.invalidate(ownerHeroDiscoverabilityProvider);
      ref.invalidate(discoverableHeroesProvider);
      ref.invalidate(heroExperienceProvider(heroIdValue));

      state = const MyHeroProfileActionState(savedSuccessfully: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to save hero profile: $e',
      );
      return false;
    }
  }
}
