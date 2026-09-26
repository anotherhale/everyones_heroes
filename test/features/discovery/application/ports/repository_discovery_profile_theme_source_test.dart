import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/discovery/discovery_profile_fixture.dart';

void main() {
  group('RepositoryDiscoveryProfileThemeSource', () {
    test('returns empty when no profile exists for the user', () async {
      final source = RepositoryDiscoveryProfileThemeSource(
        discoveryProfileRepository: InMemoryDiscoveryProfileRepository(),
        currentUserId: UserId('dev-user'),
      );

      expect(await source.currentUserNarrativeThemeIds(), isEmpty);
    });

    test('returns resolved narrative themes from the user profile', () async {
      final userId = UserId('dev-user');
      final repository = InMemoryDiscoveryProfileRepository();
      await repository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [
            NarrativeThemeId('courage'),
            NarrativeThemeId('perseverance'),
          ],
        ),
      );

      final source = RepositoryDiscoveryProfileThemeSource(
        discoveryProfileRepository: repository,
        currentUserId: userId,
      );

      final themes = await source.currentUserNarrativeThemeIds();

      expect(
        themes.map((t) => t.value).toSet(),
        {'courage', 'perseverance'},
      );
    });
  });
}
