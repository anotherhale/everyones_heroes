import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';

import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/services/influence_theme_resolver.dart';

import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

final class FakeInfluenceThemeResolver implements InfluenceThemeResolver {
  FakeInfluenceThemeResolver(this.themes);

  final List<NarrativeThemeId> themes;

  @override
  Future<List<NarrativeThemeId>> resolveThemes(
    Iterable<InfluenceId> influenceIds,
  ) async {
    return themes;
  }
}

void main() {
  group('ResolveNarrativeThemesUseCase', () {
    test('replaces narrative themes', () async {
      final repository = InMemoryDiscoveryProfileRepository();

      final profile = DiscoveryProfile(
        id: DiscoveryProfileId('profile-1'),
        userId: UserId('user-1'),
      );

      profile.addInfluence(InfluenceId('rocky'));

      await repository.save(profile);

      final courage = NarrativeThemeId('courage');

      final discipline = NarrativeThemeId('discipline');

      final useCase = ResolveNarrativeThemesUseCase(
        repository: repository,
        resolver: FakeInfluenceThemeResolver([courage, discipline]),
      );

      await useCase.execute(profile.id);

      final updated = await repository.findById(profile.id);

      expect(updated!.narrativeThemeIds, contains(courage));

      expect(updated.narrativeThemeIds, contains(discipline));

      expect(updated.narrativeThemeIds.length, 2);
    });

    test('throws when profile not found', () {
      final repository = InMemoryDiscoveryProfileRepository();

      final useCase = ResolveNarrativeThemesUseCase(
        repository: repository,
        resolver: FakeInfluenceThemeResolver([]),
      );

      expect(
        () => useCase.execute(DiscoveryProfileId('missing')),
        throwsStateError,
      );
    });
  });
}
