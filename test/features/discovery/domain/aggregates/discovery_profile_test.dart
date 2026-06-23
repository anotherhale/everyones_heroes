import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';

void main() {
  late DiscoveryProfile profile;

  setUp(() {
    profile = DiscoveryProfile(
      id: DiscoveryProfileId('profile-1'),
      userId: UserId('user-1'),
    );
  });

  group('DiscoveryProfile', () {
    test('adds influence', () {
      final influenceId = InfluenceId('influence-1');

      profile.addInfluence(influenceId);

      expect(profile.containsInfluence(influenceId), isTrue);
    });

    test('does not duplicate influence', () {
      final influenceId = InfluenceId('influence-1');

      profile.addInfluence(influenceId);
      profile.addInfluence(influenceId);

      expect(profile.influenceIds.length, 1);
    });

    test('removes influence', () {
      final influenceId = InfluenceId('influence-1');

      profile.addInfluence(influenceId);

      profile.removeInfluence(influenceId);

      expect(profile.containsInfluence(influenceId), isFalse);
    });

    test('removing missing influence is safe', () {
      profile.removeInfluence(InfluenceId('missing'));

      expect(profile.influenceIds, isEmpty);
    });

    test('replaces narrative themes', () {
      final themeA = NarrativeThemeId('theme-a');

      final themeB = NarrativeThemeId('theme-b');

      profile.replaceNarrativeThemes([themeA, themeB]);

      expect(profile.narrativeThemeIds.length, 2);

      expect(profile.containsTheme(themeA), isTrue);

      expect(profile.containsTheme(themeB), isTrue);
    });

    test('deduplicates narrative themes', () {
      final theme = NarrativeThemeId('theme-a');

      profile.replaceNarrativeThemes([theme, theme]);

      expect(profile.narrativeThemeIds.length, 1);
    });
  });
}
