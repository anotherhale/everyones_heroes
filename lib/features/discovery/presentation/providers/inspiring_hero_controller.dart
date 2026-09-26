import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';

/// UI action state for private inspiring-Hero preference (D.11).
final class InspiringHeroActionState {
  const InspiringHeroActionState({
    this.isBusy = false,
    this.errorMessage,
  });

  final bool isBusy;
  final String? errorMessage;

  InspiringHeroActionState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InspiringHeroActionState(
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final inspiringHeroControllerProvider =
    NotifierProvider.autoDispose<
      InspiringHeroController,
      InspiringHeroActionState
    >(InspiringHeroController.new);

final class InspiringHeroController extends Notifier<InspiringHeroActionState> {
  @override
  InspiringHeroActionState build() {
    return const InspiringHeroActionState();
  }

  /// Adds or removes [heroId] from DiscoveryProfile.inspiringHeroIds.
  ///
  /// Invalidates [currentDiscoveryProfileProvider] and
  /// [inspiringHeroesProvider] only — never Today / adaptive ranking.
  Future<bool> toggle(HeroId heroId) async {
    if (state.isBusy) {
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final profile = await ref.read(currentDiscoveryProfileProvider.future);
      if (profile.containsInspiringHero(heroId)) {
        await ref.read(removeInspiringHeroUseCaseProvider).execute(heroId);
      } else {
        await ref.read(addInspiringHeroUseCaseProvider).execute(heroId);
      }

      ref.invalidate(currentDiscoveryProfileProvider);
      ref.invalidate(inspiringHeroesProvider);
      state = state.copyWith(isBusy: false);
      return true;
    } on StateError catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _userFacingMessage(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Something went wrong updating your inspiring Heroes.',
      );
      return false;
    }
  }

  /// Removes [heroId] from DiscoveryProfile.inspiringHeroIds.
  Future<bool> remove(HeroId heroId) async {
    if (state.isBusy) {
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await ref.read(removeInspiringHeroUseCaseProvider).execute(heroId);
      ref.invalidate(currentDiscoveryProfileProvider);
      ref.invalidate(inspiringHeroesProvider);
      state = state.copyWith(isBusy: false);
      return true;
    } on StateError catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _userFacingMessage(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Something went wrong updating your inspiring Heroes.',
      );
      return false;
    }
  }

  String _userFacingMessage(StateError error) {
    final message = error.message;
    if (message.contains('DiscoveryProfile not found')) {
      return 'Your discovery profile could not be loaded.';
    }
    return 'Something went wrong updating your inspiring Heroes.';
  }
}
