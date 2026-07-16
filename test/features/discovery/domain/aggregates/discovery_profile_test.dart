import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/user_discovery_type.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference_type.dart';

import '../../../../fixtures/discovery/discovery_preference_fixture.dart';
import '../../../../fixtures/discovery/user_discovery_fixture.dart';

void main() {
  late DiscoveryProfile profile;

  setUp(() {
    profile = DiscoveryProfile(
      id: const DiscoveryProfileId('profile-1'),
      userId: const UserId('user-1'),
    );
  });

  group('DiscoveryProfile', () {
    group('construction', () {
      test('starts with no influences', () {
        expect(profile.influenceIds, isEmpty);
      });

      test('starts with no narrative themes', () {
        expect(profile.narrativeThemeIds, isEmpty);
      });

      test('starts with no discoveries', () {
        expect(profile.discoveries, isEmpty);
      });

      test('starts with no preferences', () {
        expect(profile.preferences, isEmpty);
      });
    });

    group('influences', () {
      test('adds influence', () {
        final influenceId = const InfluenceId('influence-1');

        profile.addInfluence(influenceId);

        expect(profile.containsInfluence(influenceId), isTrue);
      });

      test('does not duplicate influence', () {
        final influenceId = const InfluenceId('influence-1');

        profile.addInfluence(influenceId);
        profile.addInfluence(influenceId);

        expect(profile.influenceIds, hasLength(1));
      });

      test('removes influence', () {
        final influenceId = const InfluenceId('influence-1');

        profile.addInfluence(influenceId);

        profile.removeInfluence(influenceId);

        expect(profile.containsInfluence(influenceId), isFalse);
      });

      test('removing missing influence is safe', () {
        profile.removeInfluence(const InfluenceId('missing'));

        expect(profile.influenceIds, isEmpty);
      });
    });

    group('narrative themes', () {
      test('replaces narrative themes', () {
        final themeA = const NarrativeThemeId('theme-a');
        final themeB = const NarrativeThemeId('theme-b');

        profile.replaceNarrativeThemes([themeA, themeB]);

        expect(profile.narrativeThemeIds, hasLength(2));
        expect(profile.containsTheme(themeA), isTrue);
        expect(profile.containsTheme(themeB), isTrue);
      });

      test('deduplicates narrative themes', () {
        final theme = const NarrativeThemeId('theme-a');

        profile.replaceNarrativeThemes([theme, theme]);

        expect(profile.narrativeThemeIds, hasLength(1));
      });
    });

    group('discoveries', () {
      test('adds discovery', () {
        final discovery = UserDiscoveryFixture.favoriteHero();

        profile.addDiscovery(discovery);

        expect(profile.discoveries, contains(discovery));
      });

      test('does not duplicate discovery', () {
        final discovery = UserDiscoveryFixture.favoriteHero();

        profile.addDiscovery(discovery);
        profile.addDiscovery(discovery);

        expect(profile.discoveries, hasLength(1));
      });

      test('removes discovery', () {
        final discovery = UserDiscoveryFixture.favoriteHero();

        profile.addDiscovery(discovery);

        profile.removeDiscovery(discovery);

        expect(profile.discoveries, isEmpty);
      });

      test('removing missing discovery is safe', () {
        profile.removeDiscovery(UserDiscoveryFixture.favoriteHero());

        expect(profile.discoveries, isEmpty);
      });

      test('returns discoveries by type', () {
        profile.addDiscovery(UserDiscoveryFixture.favoriteHero(value: 'Rocky'));

        profile.addDiscovery(
          UserDiscoveryFixture.favoriteHero(value: 'Aragorn'),
        );

        profile.addDiscovery(UserDiscoveryFixture.favoriteBook());

        final heroes = profile.discoveriesByType(DiscoveryType.favoriteHero);

        expect(heroes, hasLength(2));

        expect(
          heroes.every((d) => d.type == DiscoveryType.favoriteHero),
          isTrue,
        );
      });
    });

    group('preferences', () {
      test('adds preference', () {
        final preference = DiscoveryPreferenceFixture.music();

        profile.updatePreference(preference);

        expect(profile.preferences, contains(preference));
      });

      test('replaces preference with same type', () {
        profile.updatePreference(
          DiscoveryPreferenceFixture.music(value: 'Epic'),
        );

        profile.updatePreference(
          DiscoveryPreferenceFixture.music(value: 'Rock'),
        );

        expect(profile.preferences, hasLength(1));

        expect(
          profile.preference(DiscoveryPreferenceType.musicStyle)!.value,
          'Rock',
        );
      });

      test('updating one preference does not replace another', () {
        profile.updatePreference(DiscoveryPreferenceFixture.music());

        profile.updatePreference(DiscoveryPreferenceFixture.coaching());

        expect(profile.preferences, hasLength(2));
      });

      test('removes preference', () {
        profile.updatePreference(DiscoveryPreferenceFixture.music());

        profile.removePreference(DiscoveryPreferenceType.musicStyle);

        expect(profile.preferences, isEmpty);
      });

      test('returns preference by type', () {
        final preference = DiscoveryPreferenceFixture.music();

        profile.updatePreference(preference);

        expect(
          profile.preference(DiscoveryPreferenceType.musicStyle),
          preference,
        );
      });

      test('returns null when preference does not exist', () {
        expect(profile.preference(DiscoveryPreferenceType.musicStyle), isNull);
      });
    });
  });
}
