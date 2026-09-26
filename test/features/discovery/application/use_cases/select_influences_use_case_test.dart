import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/list_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/select_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/services/in_memory_influence_theme_resolver.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late InMemoryInfluenceRepository influenceRepository;
  late SelectInfluencesUseCase selectInfluences;
  late ListInfluencesUseCase listInfluences;
  final userId = UserId('dev-user');

  setUp(() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    influenceRepository = InMemoryInfluenceRepository.withReferenceCatalog();
    final ensure = EnsureCurrentDiscoveryProfileUseCase(
      repository: profileRepository,
      currentUserId: userId,
    );
    final add = AddInfluenceUseCase(repository: profileRepository);
    final resolve = ResolveNarrativeThemesUseCase(
      repository: profileRepository,
      resolver: InMemoryInfluenceThemeResolver(
        influenceRepository: influenceRepository,
      ),
    );
    selectInfluences = SelectInfluencesUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      addInfluence: add,
      resolveNarrativeThemes: resolve,
      influenceRepository: influenceRepository,
    );
    listInfluences = ListInfluencesUseCase(repository: influenceRepository);
  });

  group('ListInfluencesUseCase', () {
    test('returns curated seed catalog', () async {
      final influences = await listInfluences.execute();

      expect(influences, isNotEmpty);
      expect(
        influences.map((i) => i.id),
        contains(InfluenceReferenceIds.rockyBalboa),
      );
    });
  });

  group('SelectInfluencesUseCase', () {
    test('adds Influence and resolves NarrativeThemes from catalog', () async {
      final profile = await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
      ]);

      expect(
        profile.containsInfluence(InfluenceReferenceIds.rockyBalboa),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.perseverance),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.courage),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.overcomingAdversity),
        isTrue,
      );
    });

    test('deduplicates Influence and theme IDs on repeated selection',
        () async {
      await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);
      final profile = await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.aragorn,
      ]);

      expect(
        profile.influenceIds
            .where((id) => id == InfluenceReferenceIds.rockyBalboa),
        hasLength(1),
      );
      expect(profile.containsInfluence(InfluenceReferenceIds.aragorn), isTrue);

      final themeIds = profile.narrativeThemeIds;
      expect(themeIds.toSet().length, themeIds.length);
      expect(themeIds, contains(NarrativeThemeReferenceIds.courage));
      expect(themeIds, contains(NarrativeThemeReferenceIds.leadership));
    });

    test('throws when InfluenceId is unknown', () async {
      expect(
        () => selectInfluences.execute([InfluenceId('unknown-influence')]),
        throwsStateError,
      );
    });

    test('empty selection ensures profile without themes', () async {
      final profile = await selectInfluences.execute(const []);

      expect(profile.userId, userId);
      expect(profile.influenceIds, isEmpty);
      expect(profile.narrativeThemeIds, isEmpty);
    });
  });

  group('ResolveNarrativeThemesUseCase with seeded catalog', () {
    test('resolves themes from InfluenceReferenceCatalog', () async {
      final ensure = EnsureCurrentDiscoveryProfileUseCase(
        repository: profileRepository,
        currentUserId: userId,
      );
      final profile = await ensure.execute();
      final add = AddInfluenceUseCase(repository: profileRepository);
      await add.execute(
        profileId: profile.id,
        influenceId: InfluenceReferenceIds.fredRogers,
      );

      final resolve = ResolveNarrativeThemesUseCase(
        repository: profileRepository,
        resolver: InMemoryInfluenceThemeResolver(
          influenceRepository: influenceRepository,
        ),
      );
      await resolve.execute(profile.id);

      final updated = await profileRepository.findById(profile.id);
      expect(updated!.containsTheme(NarrativeThemeReferenceIds.love), isTrue);
      expect(updated.containsTheme(NarrativeThemeReferenceIds.family), isTrue);
      expect(updated.containsTheme(NarrativeThemeReferenceIds.service), isTrue);
    });
  });
}
