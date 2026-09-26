import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/influence_selection_controller.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/get_today_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late _CountingGetTodayExperienceUseCase todayUseCase;
  late ProviderContainer container;

  setUp(() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    todayUseCase = _CountingGetTodayExperienceUseCase();
    container = ProviderContainer(
      overrides: [
        discoveryProfileRepositoryProvider.overrideWithValue(
          profileRepository,
        ),
        influenceRepositoryProvider.overrideWithValue(
          InMemoryInfluenceRepository.withReferenceCatalog(),
        ),
        getTodayExperienceUseCaseProvider.overrideWithValue(todayUseCase),
      ],
    );
  });

  tearDown(container.dispose);

  group('InfluenceSelectionController D.5', () {
    test('save persists removal and refreshes current selected state',
        () async {
      final select = container.read(selectInfluencesUseCaseProvider);
      await select.execute([InfluenceReferenceIds.rockyBalboa]);

      final before = await container.read(currentDiscoveryProfileProvider.future);
      expect(
        before.containsInfluence(InfluenceReferenceIds.rockyBalboa),
        isTrue,
      );

      final ok = await container
          .read(influenceSelectionControllerProvider.notifier)
          .save(
            influenceIdsToRemove: [InfluenceReferenceIds.rockyBalboa],
          );

      expect(ok, isTrue);
      expect(
        container.read(influenceSelectionControllerProvider).savedSuccessfully,
        isTrue,
      );

      final after = await container.read(currentDiscoveryProfileProvider.future);
      expect(
        after.containsInfluence(InfluenceReferenceIds.rockyBalboa),
        isFalse,
      );
    });

    test('save invalidates Today\'s Experience via existing mechanism',
        () async {
      await container.read(selectInfluencesUseCaseProvider).execute([
        InfluenceReferenceIds.rockyBalboa,
      ]);

      // Prime the Today provider.
      await container.read(todayExperienceProvider.future);
      expect(todayUseCase.executeCount, 1);

      await container
          .read(influenceSelectionControllerProvider.notifier)
          .save(
            influenceIdsToRemove: [InfluenceReferenceIds.rockyBalboa],
          );

      // Re-read after invalidation should re-execute the use case.
      await container.read(todayExperienceProvider.future);
      expect(todayUseCase.executeCount, greaterThan(1));
    });

    test('save with adds still works after D.5 signature change', () async {
      final ok = await container
          .read(influenceSelectionControllerProvider.notifier)
          .save(
            influenceIdsToAdd: [InfluenceReferenceIds.aragorn],
          );

      expect(ok, isTrue);
      final profile =
          await container.read(currentDiscoveryProfileProvider.future);
      expect(
        profile.containsInfluence(InfluenceReferenceIds.aragorn),
        isTrue,
      );
    });
  });
}

final class _CountingGetTodayExperienceUseCase
    implements GetTodayExperienceUseCase {
  int executeCount = 0;

  @override
  Future<Result<AdaptiveExperience>> execute() async {
    executeCount++;
    return const Success(
      AdaptiveExperience(
        id: 'test-experience',
        type: ExperienceType.reflection,
        title: 'Test',
        description: 'Test experience.',
        action: ExperienceAction.begin,
      ),
    );
  }
}
