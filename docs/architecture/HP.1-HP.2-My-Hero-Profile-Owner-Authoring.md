# HP.1 / HP.2 — My Hero Profile Owner Authoring

## Summary

Owner-facing authoring for existing `HeroProfile` fields on the active local Hero.

Does **not** introduce a new aggregate. Uses:

* `Hero`
* `HeroProfile`
* `ActiveLocalHeroStore`
* `UpdateHeroProfileUseCase`
* `GetMyHeroUseCase` (owner read without discoverability gate)

## Editable fields

* displayName (required)
* biography (optional)
* experienceAreas (`List<String>`, no taxonomy)
* languages (`LanguageCode`)
* geographicContext (optional)

## Explicitly deferred

* achievements / service / professional / lived-experience fields
* profile media
* follow / inspire / bookmark
* Identity binding
* AI profile inference
* automatic discoverability on save

## Surfaces

* Owner: My Stories → My Hero Profile (`MyHeroProfileScreen`)
* Seeker: `HeroProfileScreen` (read-only; shows geographicContext + languages)

## Composition

```text
ActiveLocalHeroStore
  → active HeroId
  → GetMyHeroUseCase / HeroRepository
  → Hero (private OK)

UI save
  → UpdateHeroProfileUseCase
  → Hero.updateProfile
  → HeroRepository.save
  → HeroProfileUpdated
```

Profile editing and discoverability remain separate concerns.
