import 'package:everyonesheroes/features/discovery/presentation/widgets/inspires_me_toggle.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_profile_action_provider.dart';

/// D.11 wiring: inject private "Inspires me" into seeker Hero profile.
///
/// Used by [AppCompositionRoot] so Hero & Story never imports Discovery.
HeroProfileActionBuilder get inspiringHeroProfileActionBuilder {
  return ({required ref, required heroId}) {
    return InspiresMeToggle(heroId: heroId);
  };
}
