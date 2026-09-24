import 'dart:collection';

import 'package:eh_platform/src/shared_kernel/entity.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';

/// Discovery-owned NarrativeTheme reference entity.
///
/// Catalog vocabulary for adaptive discovery / theme overlap. Not a
/// personalization decision and not a Behavior Pattern.
final class NarrativeTheme extends Entity<NarrativeThemeId> {
  NarrativeTheme({
    required NarrativeThemeId id,
    required String name,
    required String description,
    Iterable<String>? aliases,
  })  : _name = name.trim(),
        _description = description.trim(),
        _aliases =
            aliases
                ?.map((alias) => alias.trim())
                .where((alias) => alias.isNotEmpty)
                .toList(growable: false) ??
            const [],
        super(id) {
    if (_name.isEmpty) {
      throw ArgumentError('Theme name cannot be empty.');
    }
  }

  final String _name;
  final String _description;
  final List<String> _aliases;

  String get name => _name;

  String get description => _description;

  UnmodifiableListView<String> get aliases => UnmodifiableListView(_aliases);
}
