import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/select_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/services/in_memory_influence_theme_resolver.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late InMemoryInfluenceRepository influenceRepository;
  late SelectInfluencesUseCase selectInfluences;
  late RemoveInfluenceUseCase removeInfluence;
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
    removeInfluence = RemoveInfluenceUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: profileRepository,
      resolveNarrativeThemes: resolve,
    );
  });

  group('RemoveInfluenceUseCase', () {
    test('removes an existing Influence from the profile', () async {
      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.aragorn,
      ]);

      final profile = await removeInfluence.execute(
        InfluenceReferenceIds.rockyBalboa,
      );

      expect(
        profile.containsInfluence(InfluenceReferenceIds.rockyBalboa),
        isFalse,
      );
      expect(
        profile.containsInfluence(InfluenceReferenceIds.aragorn),
        isTrue,
      );
    });

    test('removing a nonexistent Influence is safe (no-op)', () async {
      await selectInfluences.execute([InfluenceReferenceIds.aragorn]);

      final profile = await removeInfluence.execute(
        InfluenceReferenceIds.rockyBalboa,
      );

      expect(
        profile.containsInfluence(InfluenceReferenceIds.aragorn),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.leadership),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.courage),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.sacrifice),
        isTrue,
      );
    });

    test('recomputes themes after removal — exclusive themes disappear',
        () async {
      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.aragorn,
      ]);

      final before = await profileRepository.findByUserId(userId);
      expect(
        before!.containsTheme(NarrativeThemeReferenceIds.perseverance),
        isTrue,
      );
      expect(
        before.containsTheme(NarrativeThemeReferenceIds.overcomingAdversity),
        isTrue,
      );
      expect(
        before.containsTheme(NarrativeThemeReferenceIds.courage),
        isTrue,
      );
      expect(
        before.containsTheme(NarrativeThemeReferenceIds.leadership),
        isTrue,
      );

      final profile = await removeInfluence.execute(
        InfluenceReferenceIds.rockyBalboa,
      );

      // Rocky-exclusive themes removed.
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.perseverance),
        isFalse,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.overcomingAdversity),
        isFalse,
      );
      // Aragorn themes retained (including shared courage).
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.courage),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.leadership),
        isTrue,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.sacrifice),
        isTrue,
      );
    });

    test('shared themes remain when another Influence still supplies them',
        () async {
      // Rocky and Aragorn both supply courage.
      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.aragorn,
      ]);

      final profile = await removeInfluence.execute(
        InfluenceReferenceIds.rockyBalboa,
      );

      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.courage),
        isTrue,
      );
    });

    test('updated profile is persisted with no stale themes', () async {
      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.fredRogers,
      ]);

      await removeInfluence.execute(InfluenceReferenceIds.rockyBalboa);

      final persisted = await profileRepository.findByUserId(userId);
      expect(persisted, isNotNull);
      expect(
        persisted!.containsInfluence(InfluenceReferenceIds.rockyBalboa),
        isFalse,
      );
      expect(
        persisted.containsInfluence(InfluenceReferenceIds.fredRogers),
        isTrue,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.perseverance),
        isFalse,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.overcomingAdversity),
        isFalse,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.courage),
        isFalse,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.love),
        isTrue,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.family),
        isTrue,
      );
      expect(
        persisted.containsTheme(NarrativeThemeReferenceIds.service),
        isTrue,
      );

      // Invariant: themes == union of remaining Influences.
      expect(
        persisted.narrativeThemeIds.toSet(),
        {
          NarrativeThemeReferenceIds.love,
          NarrativeThemeReferenceIds.family,
          NarrativeThemeReferenceIds.service,
        },
      );
    });

    test('removing unknown InfluenceId that was never selected is safe',
        () async {
      final profile = await removeInfluence.execute(
        InfluenceId('never-selected-influence'),
      );

      expect(profile.influenceIds, isEmpty);
      expect(profile.narrativeThemeIds, isEmpty);
    });
  });
}
