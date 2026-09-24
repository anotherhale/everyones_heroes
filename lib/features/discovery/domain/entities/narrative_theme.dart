import 'package:collection/collection.dart';

import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';

final class NarrativeTheme extends Entity<NarrativeThemeId> {
  NarrativeTheme({
    required NarrativeThemeId id,
    required String name,
    required String description,
    Iterable<String>? aliases,
  }) : _name = name.trim(),
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

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NarrativeTheme &&
            id == other.id &&
            _equality.equals(name, other.name) &&
            _equality.equals(description, other.description) &&
            _equality.equals(aliases, other.aliases);
  }

  @override
  int get hashCode => Object.hash(
        id,
        _equality.hash(name),
        _equality.hash(description),
        _equality.hash(aliases),
      );
}
