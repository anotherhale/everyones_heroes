import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/understood_theme_origin.dart';

/// A theme discovered or declared for Story Builder material (SB.8).
///
/// Reuses [StoryBuilderTheme] vocabulary — does not invent a second taxonomy.
final class UnderstoodTheme extends ValueObject {
  UnderstoodTheme({
    required this.theme,
    required this.origin,
    Iterable<StoryBuilderResponseId>? sourceResponseIds,
  }) : sourceResponseIds = List.unmodifiable(
         sourceResponseIds?.toList() ?? const <StoryBuilderResponseId>[],
       ) {
    if (origin == UnderstoodThemeOrigin.derivedFromResponses &&
        this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'Derived themes require at least one sourceResponseId.',
      );
    }
  }

  final StoryBuilderTheme theme;
  final UnderstoodThemeOrigin origin;
  final List<StoryBuilderResponseId> sourceResponseIds;

  @override
  List<Object?> get equalityProps => [
    theme,
    origin,
    ...sourceResponseIds,
  ];
}
