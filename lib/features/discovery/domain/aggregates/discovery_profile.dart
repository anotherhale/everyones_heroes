import 'dart:collection';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/features/discovery/domain/events/influence_added.dart';
import 'package:everyonesheroes/features/discovery/domain/events/influence_removed.dart';
import 'package:everyonesheroes/features/discovery/domain/events/narrative_themes_resolved.dart';

final class DiscoveryProfile extends AggregateRoot<DiscoveryProfileId> {
  DiscoveryProfile({
    required DiscoveryProfileId id,
    required this._userId,
    Iterable<InfluenceId>? influenceIds,
    Iterable<NarrativeThemeId>? narrativeThemeIds,
  }) : _influenceIds = influenceIds?.toSet().toList() ?? [],
       _narrativeThemeIds = narrativeThemeIds?.toSet().toList() ?? [],
       super(id);

  final UserId _userId;

  final List<InfluenceId> _influenceIds;

  final List<NarrativeThemeId> _narrativeThemeIds;

  UserId get userId => _userId;

  UnmodifiableListView<InfluenceId> get influenceIds =>
      UnmodifiableListView(_influenceIds);

  UnmodifiableListView<NarrativeThemeId> get narrativeThemeIds =>
      UnmodifiableListView(_narrativeThemeIds);

  bool containsInfluence(InfluenceId influenceId) {
    return _influenceIds.contains(influenceId);
  }

  bool containsTheme(NarrativeThemeId themeId) {
    return _narrativeThemeIds.contains(themeId);
  }

  void addInfluence(InfluenceId influenceId) {
    if (_influenceIds.contains(influenceId)) {
      return;
    }

    _influenceIds.add(influenceId);

    raise(
      InfluenceAdded(
        aggregateId: id.value,
        discoveryProfileId: id,
        influenceId: influenceId,
      ),
    );
  }

  void removeInfluence(InfluenceId influenceId) {
    final removed = _influenceIds.remove(influenceId);

    if (!removed) {
      return;
    }

    raise(
      InfluenceRemoved(
        aggregateId: id.value,
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
        aggregateId: id.value,
        discoveryProfileId: id,
        themeIds: List.unmodifiable(_narrativeThemeIds),
      ),
    );
  }
}
