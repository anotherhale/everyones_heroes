import 'dart:collection';

import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/user_discovery.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/user_discovery_type.dart';
import 'package:everyonesheroes/features/discovery/domain/events/influence_added.dart';
import 'package:everyonesheroes/features/discovery/domain/events/influence_removed.dart';
import 'package:everyonesheroes/features/discovery/domain/events/narrative_themes_resolved.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference_type.dart';

final class DiscoveryProfile extends AggregateRoot<DiscoveryProfileId> {
  DiscoveryProfile({
    required DiscoveryProfileId id,
    required UserId userId,
    Iterable<InfluenceId>? influenceIds,
    Iterable<NarrativeThemeId>? narrativeThemeIds,
    Iterable<UserDiscovery>? discoveries,
    Iterable<DiscoveryPreference>? preferences,
  }) : _userId = userId,
       _influenceIds = influenceIds?.toSet().toList() ?? [],
       _narrativeThemeIds = narrativeThemeIds?.toSet().toList() ?? [],
       _discoveries = discoveries?.toList() ?? [],
       _preferences = preferences?.toList() ?? [],
       super(id);

  final UserId _userId;

  final List<InfluenceId> _influenceIds;

  final List<NarrativeThemeId> _narrativeThemeIds;

  final List<UserDiscovery> _discoveries;

  final List<DiscoveryPreference> _preferences;

  UserId get userId => _userId;

  UnmodifiableListView<InfluenceId> get influenceIds =>
      UnmodifiableListView(_influenceIds);

  UnmodifiableListView<NarrativeThemeId> get narrativeThemeIds =>
      UnmodifiableListView(_narrativeThemeIds);

  UnmodifiableListView<UserDiscovery> get discoveries =>
      UnmodifiableListView(_discoveries);

  UnmodifiableListView<DiscoveryPreference> get preferences =>
      UnmodifiableListView(_preferences);

  bool containsInfluence(InfluenceId influenceId) =>
      _influenceIds.contains(influenceId);

  bool containsTheme(NarrativeThemeId themeId) =>
      _narrativeThemeIds.contains(themeId);

  bool containsDiscovery(UserDiscovery discovery) =>
      _discoveries.contains(discovery);

  UnmodifiableListView<UserDiscovery> discoveriesByType(DiscoveryType type) =>
      UnmodifiableListView(_discoveries.where((d) => d.type == type));

  DiscoveryPreference? preference(DiscoveryPreferenceType type) {
    for (final preference in _preferences) {
      if (preference.type == type) {
        return preference;
      }
    }
    return null;
  }

  void addInfluence(InfluenceId influenceId) {
    if (_influenceIds.contains(influenceId)) {
      return;
    }

    _influenceIds.add(influenceId);

    raise(
      InfluenceAdded(
        aggregateId: id,
        discoveryProfileId: id,
        influenceId: influenceId,
      ),
    );
  }

  void removeInfluence(InfluenceId influenceId) {
    if (!_influenceIds.remove(influenceId)) {
      return;
    }

    raise(
      InfluenceRemoved(
        aggregateId: id,
        discoveryProfileId: id,
        influenceId: influenceId,
      ),
    );
  }

  void replaceNarrativeThemes(Iterable<NarrativeThemeId> themeIds) {
    _narrativeThemeIds
      ..clear()
      ..addAll(themeIds.toSet());

    raise(
      NarrativeThemesResolved(
        aggregateId: id,
        discoveryProfileId: id,
        themeIds: List.unmodifiable(_narrativeThemeIds),
      ),
    );
  }

  void addDiscovery(UserDiscovery discovery) {
    if (_discoveries.contains(discovery)) {
      return;
    }

    _discoveries.add(discovery);

    // TODO(Phase H.2):
    // raise(
    //   DiscoveryAdded(...),
    // );
  }

  void removeDiscovery(UserDiscovery discovery) {
    if (!_discoveries.remove(discovery)) {
      return;
    }

    // TODO(Phase H.2):
    // raise(
    //   DiscoveryRemoved(...),
    // );
  }

  void updatePreference(DiscoveryPreference preference) {
    _preferences.removeWhere((p) => p.type == preference.type);
    _preferences.add(preference);

    // TODO(Phase H.2):
    // raise(
    //   PreferenceUpdated(...),
    // );
  }

  void removePreference(DiscoveryPreferenceType type) {
    _preferences.removeWhere((p) => p.type == type);

    // TODO(Phase H.2):
    // raise(
    //   PreferenceRemoved(...),
    // );
  }
}
