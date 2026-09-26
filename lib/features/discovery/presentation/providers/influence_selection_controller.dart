import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/explore_stories_by_inspiration_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';

/// UI action state for curated Influence selection (D.3 / D.5).
final class InfluenceSelectionActionState {
  const InfluenceSelectionActionState({
    this.isBusy = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  final bool isBusy;
  final String? errorMessage;
  final bool savedSuccessfully;

  InfluenceSelectionActionState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool? savedSuccessfully,
    bool clearError = false,
    bool clearSaved = false,
  }) {
    return InfluenceSelectionActionState(
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully:
          clearSaved ? false : (savedSuccessfully ?? this.savedSuccessfully),
    );
  }
}

final influenceSelectionControllerProvider =
    NotifierProvider.autoDispose<
      InfluenceSelectionController,
      InfluenceSelectionActionState
    >(InfluenceSelectionController.new);

final class InfluenceSelectionController
    extends Notifier<InfluenceSelectionActionState> {
  @override
  InfluenceSelectionActionState build() {
    return const InfluenceSelectionActionState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSavedFlag() {
    state = state.copyWith(clearSaved: true);
  }

  /// Persists Influence adds and removals through application use cases.
  ///
  /// Removals run first ([RemoveInfluenceUseCase]), then adds
  /// ([SelectInfluencesUseCase]). Each mutation re-resolves Narrative Themes
  /// from the current Influence set.
  ///
  /// Invalidates [currentDiscoveryProfileProvider],
  /// [inspirationGroundedStoriesProvider], and [todayExperienceProvider]
  /// after a successful save.
  ///
  /// Does not emit BehavioralEvidence.
  Future<bool> save({
    Iterable<InfluenceId> influenceIdsToAdd = const [],
    Iterable<InfluenceId> influenceIdsToRemove = const [],
  }) async {
    if (state.isBusy) {
      return false;
    }

    final toAdd = influenceIdsToAdd.toSet().toList(growable: false);
    final toRemove = influenceIdsToRemove.toSet().toList(growable: false);
    if (toAdd.isEmpty && toRemove.isEmpty) {
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true, clearSaved: true);

    try {
      for (final influenceId in toRemove) {
        await ref.read(removeInfluenceUseCaseProvider).execute(influenceId);
      }

      if (toAdd.isNotEmpty) {
        await ref.read(selectInfluencesUseCaseProvider).execute(toAdd);
      }

      ref.invalidate(currentDiscoveryProfileProvider);
      ref.invalidate(inspirationGroundedStoriesProvider);
      ref.invalidate(todayExperienceProvider);
      state = state.copyWith(isBusy: false, savedSuccessfully: true);
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
        errorMessage: 'Something went wrong saving your inspirations.',
      );
      return false;
    }
  }

  String _userFacingMessage(StateError error) {
    final message = error.message;
    if (message.contains('Influence not found')) {
      return 'That inspiration is no longer available.';
    }
    if (message.contains('DiscoveryProfile not found')) {
      return 'Your discovery profile could not be loaded.';
    }
    return 'Something went wrong saving your inspirations.';
  }
}
