import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/get_today_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';

final todayExperienceProvider =
    FutureProvider.autoDispose<TodayExperienceViewModel>((ref) async {
  final useCase = ref.read(getTodayExperienceUseCaseProvider);
  final cache = ref.read(todayExperienceCacheProvider);

  final result = await useCase.execute();

  return result.fold(
    onSuccess: (experience) => TodayExperienceViewModel.fromExperience(
      experience,
      isStale: cache.lastReadWasStale,
    ),
    onFailure: (error) => throw Exception(error),
  );
});
