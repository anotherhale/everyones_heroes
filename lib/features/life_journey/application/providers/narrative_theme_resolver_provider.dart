import 'package:everyonesheroes/features/life_journey/application/providers/fake/fake_narrative_theme_resolver.dart';
import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final narrativeThemeResolverProvider = Provider<NarrativeThemeResolver>((ref) {
  return FakeNarrativeThemeResolver();
});
