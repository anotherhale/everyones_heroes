import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/owned_story_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owner_hero_discoverability_view_model.dart';

/// Active owner's Hero for discoverability settings (HS.FG.3).
///
/// Reads the canonical Hero from the repository via the local bootstrap path.
/// Does not invent a second Hero aggregate or visibility model.
final ownerHeroDiscoverabilityProvider =
    FutureProvider.autoDispose<OwnerHeroDiscoverabilityViewModel>((ref) async {
      final hero = await ref.watch(ensureActiveLocalHeroProvider.future);
      return OwnerHeroDiscoverabilityViewModel.fromHero(hero);
    });

/// UI action state for changing Hero discoverability.
final class OwnerHeroDiscoverabilityActionState {
  const OwnerHeroDiscoverabilityActionState({
    this.isBusy = false,
    this.errorMessage,
  });

  final bool isBusy;
  final String? errorMessage;

  OwnerHeroDiscoverabilityActionState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerHeroDiscoverabilityActionState(
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final ownerHeroDiscoverabilityControllerProvider = NotifierProvider.autoDispose<
    OwnerHeroDiscoverabilityController,
    OwnerHeroDiscoverabilityActionState>(
  OwnerHeroDiscoverabilityController.new,
);

final class OwnerHeroDiscoverabilityController
    extends Notifier<OwnerHeroDiscoverabilityActionState> {
  @override
  OwnerHeroDiscoverabilityActionState build() {
    return const OwnerHeroDiscoverabilityActionState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Sets Hero to a discoverable catalog visibility ([HeroVisibility.public]).
  Future<bool> makeDiscoverable() {
    return _changeVisibility(HeroVisibility.public);
  }

  /// Sets Hero to [HeroVisibility.private] (not catalog-discoverable).
  Future<bool> makePrivate() {
    return _changeVisibility(HeroVisibility.private);
  }

  Future<bool> _changeVisibility(HeroVisibility visibility) async {
    if (state.isBusy) {
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final result = await ref.read(changeHeroVisibilityUseCaseProvider).execute(
            ChangeHeroVisibilityRequest(
              heroId: hero.id,
              ownerHeroId: hero.id,
              visibility: visibility,
            ),
          );

      if (result is Failure<Hero>) {
        state = state.copyWith(isBusy: false, errorMessage: result.error);
        return false;
      }

      // Invalidate only after persistence succeeds so UI reflects canonical
      // state — never optimistic.
      ref.invalidate(ensureActiveLocalHeroProvider);
      ref.invalidate(ownerHeroDiscoverabilityProvider);
      state = const OwnerHeroDiscoverabilityActionState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to change hero visibility: $e',
      );
      return false;
    }
  }
}
