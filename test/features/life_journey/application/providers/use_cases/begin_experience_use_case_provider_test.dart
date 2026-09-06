import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';

void main() {
  test('provides BeginExperienceUseCase', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final useCase = container.read(beginExperienceUseCaseProvider);

    expect(useCase, isA<BeginExperienceUseCase>());
  });
}
