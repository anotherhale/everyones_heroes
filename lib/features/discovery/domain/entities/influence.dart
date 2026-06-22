import 'dart:collection';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/influence_category.dart';

final class Influence extends Entity<InfluenceId> {
  Influence({
    required InfluenceId id,
    required String canonicalName,
    required InfluenceCategory category,
    required Iterable<NarrativeThemeId> narrativeThemeIds,
    Iterable<String>? aliases,
    String? description,
    String? imageReference,
  }) : _canonicalName = canonicalName.trim(),
       _category = category,
       _description = description?.trim(),
       _imageReference = imageReference?.trim(),
       _aliases =
           aliases
               ?.map((alias) => alias.trim())
               .where((alias) => alias.isNotEmpty)
               .toList() ??
           [],
       _narrativeThemeIds = narrativeThemeIds.toSet().toList(),
       super(id) {
    if (_canonicalName.isEmpty) {
      throw ArgumentError('Influence name cannot be empty.');
    }

    if (_narrativeThemeIds.isEmpty) {
      throw ArgumentError(
        'Influence must contain at least one narrative theme.',
      );
    }
  }

  final String _canonicalName;

  final InfluenceCategory _category;

  final String? _description;

  final String? _imageReference;

  final List<String> _aliases;

  final List<NarrativeThemeId> _narrativeThemeIds;

  String get canonicalName => _canonicalName;

  InfluenceCategory get category => _category;

  String? get description => _description;

  String? get imageReference => _imageReference;

  UnmodifiableListView<String> get aliases => UnmodifiableListView(_aliases);

  UnmodifiableListView<NarrativeThemeId> get narrativeThemeIds =>
      UnmodifiableListView(_narrativeThemeIds);

  bool get hasDescription => _description != null && _description.isNotEmpty;

  bool get hasImage => _imageReference != null && _imageReference.isNotEmpty;

  bool containsTheme(NarrativeThemeId themeId) {
    return _narrativeThemeIds.contains(themeId);
  }

  bool matchesName(String value) {
    final search = value.trim().toLowerCase();

    if (_canonicalName.toLowerCase() == search) {
      return true;
    }

    return _aliases.any((alias) => alias.toLowerCase() == search);
  }

  void addTheme(NarrativeThemeId themeId) {
    final exists = _narrativeThemeIds.contains(themeId);

    if (exists) {
      return;
    }

    _narrativeThemeIds.add(themeId);
  }

  void removeTheme(NarrativeThemeId themeId) {
    if (_narrativeThemeIds.length == 1 && _narrativeThemeIds.first == themeId) {
      throw StateError('Influence must have at least one narrative theme.');
    }

    _narrativeThemeIds.remove(themeId);
  }

  void addAlias(String alias) {
    final normalized = alias.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('Alias cannot be empty.');
    }

    final exists = _aliases.any(
      (existing) => existing.toLowerCase() == normalized.toLowerCase(),
    );

    if (exists) {
      return;
    }

    _aliases.add(normalized);
  }

  void removeAlias(String alias) {
    _aliases.removeWhere(
      (existing) => existing.toLowerCase() == alias.trim().toLowerCase(),
    );
  }
}
