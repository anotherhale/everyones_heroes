import 'package:collection/collection.dart';

import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';

final class NarrativeTheme extends Entity<NarrativeThemeId> {
  NarrativeTheme({
    required this.id,
    required String name,
    required String description,
  }) : _name = name.trim(),
       _description = description.trim(),
       super(id) {
    if (_name.isEmpty) {
      throw ArgumentError('Theme name cannot be empty.');
    }
  }

  final NarrativeThemeId id;

  final String _name;

  final String _description;

  String get name => _name;

  String get description => _description;

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NarrativeTheme &&
            id == other.id &&
            _equality.equals(name, other.name) &&
            _equality.equals(description, other.description);
  }

  @override
  int get hashCode =>
      Object.hash(id, _equality.hash(name), _equality.hash(description));
}
