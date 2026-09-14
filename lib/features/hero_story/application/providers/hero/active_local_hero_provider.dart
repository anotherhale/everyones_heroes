import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

/// Temporary local Hero bootstrap until Identity BC exists (HS-ADR-065).
///
/// Persists the active Hero id under the storage root when available; otherwise
/// keeps it in memory for the process lifetime.
final class ActiveLocalHeroStore {
  ActiveLocalHeroStore({Directory? storageRoot})
    : _idFile = storageRoot == null
          ? null
          : File(p.join(storageRoot.path, 'active_hero_id.txt'));

  final File? _idFile;
  HeroId? _cached;

  HeroId? get currentId => _cached;

  Future<HeroId?> load() async {
    if (_cached != null) {
      return _cached;
    }
    final file = _idFile;
    if (file != null && await file.exists()) {
      final raw = (await file.readAsString()).trim();
      if (raw.isNotEmpty) {
        _cached = HeroId(raw);
        return _cached;
      }
    }
    return null;
  }

  Future<void> setActive(HeroId heroId) async {
    _cached = heroId;
    final file = _idFile;
    if (file != null) {
      await file.parent.create(recursive: true);
      await file.writeAsString(heroId.value, flush: true);
    }
  }
}

final activeLocalHeroStoreProvider = Provider<ActiveLocalHeroStore>((ref) {
  return ActiveLocalHeroStore();
});

/// Ensures a local active Hero exists for capture (HS.9 bootstrap).
final ensureActiveLocalHeroProvider = FutureProvider<Hero>((ref) async {
  final store = ref.watch(activeLocalHeroStoreProvider);
  final heroes = ref.watch(heroRepositoryProvider);
  final createHero = ref.watch(createHeroUseCaseProvider);

  final existingId = await store.load();
  if (existingId != null) {
    final existing = await heroes.findById(existingId);
    if (existing != null && existing.isActive) {
      return existing;
    }
  }

  // Prefer any existing active hero before creating another.
  final all = await heroes.findAll();
  for (final hero in all) {
    if (hero.isActive) {
      await store.setActive(hero.id);
      return hero;
    }
  }

  final result = await createHero.execute(
    CreateHeroRequest(
      heroId: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Local Hero',
        biography: 'Development bootstrap hero until Identity BC exists.',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.private,
    ),
  );

  if (result is Failure<Hero>) {
    throw StateError(result.error);
  }

  final hero = (result as Success<Hero>).value;
  await store.setActive(hero.id);
  return hero;
});
