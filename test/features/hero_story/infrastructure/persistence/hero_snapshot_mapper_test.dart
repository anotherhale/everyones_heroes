import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/hero_snapshot_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeroSnapshotMapper', () {
    test('round-trips hero snapshot without raising domain events', () {
      final createdAt = DateTime.utc(2024, 5, 1, 12, 30);
      final hero = Hero(
        id: const HeroId('hero-1'),
        identityUserId: const UserId('user-1'),
        profile: HeroProfile(
          displayName: 'Jordan Hale',
          biography: 'Firefighter mentor.',
          experienceAreas: const ['Leadership', 'Service'],
          languages: [LanguageCode('en'), LanguageCode('es')],
          geographicContext: 'Austin, TX',
        ),
        visibility: HeroVisibility.community,
        status: HeroStatus.active,
        createdAt: createdAt,
      );

      final json = HeroSnapshotMapper.toJson(hero);
      final restored = HeroSnapshotMapper.fromJson(json);

      expect(restored.id, hero.id);
      expect(restored.identityUserId, hero.identityUserId);
      expect(restored.profile.displayName, 'Jordan Hale');
      expect(restored.profile.biography, 'Firefighter mentor.');
      expect(restored.profile.experienceAreas, ['Leadership', 'Service']);
      expect(restored.profile.languages.map((l) => l.value), ['en', 'es']);
      expect(restored.profile.geographicContext, 'Austin, TX');
      expect(restored.visibility, HeroVisibility.community);
      expect(restored.status, HeroStatus.active);
      expect(restored.createdAt.toUtc(), createdAt);
      expect(restored.pullDomainEvents(), isEmpty);

      expect(json['visibility'], 'community');
      expect(json['status'], 'active');
      expect(json['createdAt'], createdAt.toIso8601String());
    });

    test('handles null optional identity and profile fields', () {
      final hero = Hero(
        id: const HeroId('hero-2'),
        profile: HeroProfile(displayName: 'Minimal'),
        createdAt: DateTime.utc(2025, 1, 1),
      );

      final restored = HeroSnapshotMapper.fromJson(
        HeroSnapshotMapper.toJson(hero),
      );

      expect(restored.identityUserId, isNull);
      expect(restored.profile.biography, isNull);
      expect(restored.profile.geographicContext, isNull);
      expect(restored.profile.experienceAreas, isEmpty);
      expect(restored.profile.languages, isEmpty);
    });
  });
}
