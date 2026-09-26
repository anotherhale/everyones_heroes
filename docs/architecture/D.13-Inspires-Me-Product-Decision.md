# D.13 — “Inspires Me” Product Decision

- **Document type:** Product / Architecture Decision Record
- **Status:** Accepted — Decision: **Not Yet**
- **Phase:** D.13 “Inspires Me” Product Semantics
- **Baseline:** D.11 Explicit Hero Inspiration Relationship; D.12 Discovery-to-Personalization Boundary Assessment (chat assessment; not a separate repo doc)
- **Date:** 2026-09-26
- **ADR index:** `D-ADR-001` in `docs/architecture/architecture-decisions.md`

---

## Product Decision

**Decision: Not Yet**

“Inspires Me” is an explicit, private, current-state Discovery preference that a
seeker has selected for a Hero.

The system remembers the relationship, but its **downstream behavioral meaning
has intentionally not yet been defined**.

This is **Not Yet**, not **E / informational only**.

| Stance | Meaning |
|--------|---------|
| **E / informational only** | EH has intentionally decided the preference will remain informational and will **not** influence future behavior. |
| **Not Yet** (authoritative) | EH intentionally captures the preference because it **may** become useful to future Personalization, but the product has **not yet defined** what downstream behavior that preference should imply. |

Do not document “Inspires Me” as permanently informational.

---

## Current behavior (unchanged from D.11)

The preference currently:

* persists in `DiscoveryProfile.inspiringHeroIds`
* appears through the **Inspires Me** Hero UI
* appears in the user’s **Heroes Who Inspire Me** Discovery surface
* can be removed by the user

It currently does **not** participate in:

* Today
* Story ranking
* Explore Stories
* Adaptive Discovery signals (`AdaptiveDiscoverySignals`)
* Narrative Theme derivation / resolution
* Behavioral Evidence
* Behavior Patterns
* Personalization
* Hero ranking / Hero discovery ranking
* Hero-specific experience generation / experience selection

D.11 implementation remains valid and does **not** need to change.

---

## Future status

Treat `inspiringHeroIds` as a **future personalization input**, not a current
recommendation signal.

Do **not** define what that future input means yet.

Possible future semantics remain **explicitly unresolved**, including:

* prefer Stories from an inspiring Hero
* derive Story affinity from an inspiring Hero
* derive Narrative Themes from an inspiring Hero
* generate Hero-specific experiences
* another product-defined interpretation

Do **not** select among these alternatives in documentation or code until a
subsequent explicit product decision does so.

Architectural rule (preserved from D.11):

> Relationship existence ≠ recommendation signal.

---

## Evidence-first boundary

“Inspires Me” is an **explicit preference**, not observed behavioral evidence.

Do **not** introduce it into the behavioral evidence pipeline.

Current conceptual path remains:

```text
Experience
    ↓
Reflection
    ↓
Behavioral Evidence
    ↓
Behavior Pattern
    ↓
Growth Opportunity   ← future / not yet a domain model
    ↓
[future] Personalization
    ↓
Experience
```

Do **not** imply:

```text
Inspires Me → Behavioral Evidence
```

or:

```text
Inspiring Hero → Behavior Pattern
```

Growth Opportunity remains a future concept. This decision does not implement
Growth Opportunities.

---

## Context boundaries (preserved)

```text
Discovery
  = what currently inspires/interests the person
Life Journey
  = what the person actually does/experiences
Hero & Story
  = the available Hero/Story content
Personalization
  = future decision about what experience is relevant now
Experience
  = delivery of that experience
```

Personalization is **not** currently an implemented bounded context or engine.
`AdaptiveDiscoverySignals` is a Life Journey application DTO for deterministic
Story selection + explanation — not a Personalization contract.

`inspiringHeroIds` is **not** currently part of `AdaptiveDiscoverySignals` and
must not be added merely because it exists on `DiscoveryProfile`. Any future use
requires an explicit product decision defining the semantic bridge between Hero
inspiration and experience selection.

---

## Non-goals of this decision

This decision does **not** establish:

* Hero → NarrativeTheme derivation
* Hero → Story affinity
* Story ranking boosts
* Hero ranking
* recommendation behavior
* social / follow semantics
* behavioral evidence from inspiration
* AI inference about why a Hero inspires someone
* a Personalization Engine
* Growth Opportunity domain model or lifecycle

---

## Relationship to prior work

| Artifact | Role |
|----------|------|
| D.10 (assessment) | Authorized an explicit private Hero inspiration preference |
| D.11 | Implemented `inspiringHeroIds` + UI; adaptive boundary unchanged |
| D.12 (assessment) | Established Discovery ≠ Personalization; inspiring Heroes off Today path |
| **D.13 (this doc)** | Authoritative product stance: downstream meaning = **Not Yet** |

---

## Authoritative statement

> “Inspires Me” is a remembered preference, not currently a recommendation
> instruction. Its downstream semantic meaning is intentionally **Not Yet
> Defined**. No current Today, ranking, theme, behavioral, or personalization
> behavior should be inferred from the existence of `inspiringHeroIds`.
