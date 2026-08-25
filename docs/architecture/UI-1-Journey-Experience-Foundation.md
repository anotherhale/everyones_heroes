# UI.1 — Journey Experience Foundation

## Purpose

UI.1 establishes the first real **Everyone's Heroes product experience**.

The goal is not to complete the entire UI, nor to build every planned feature. The goal is to create a coherent, demonstrable Journey experience that establishes the visual language, application shell, presentation architecture, and first vertical user flow.

The UI should make the core product concept understandable without requiring someone to understand the underlying domain model:

> **Everyone's Heroes helps a person understand who they are becoming and take meaningful steps toward it.**

The initial experience should therefore emphasize:

**Journey → Next Step → Reflection/Growth**

---

## UI.1 Scope

UI.1 consists of five primary areas.

### 1. Application Shell

Establish the initial Flutter application structure:

```text
ProviderScope
    ↓
Everyone's Heroes App
    ↓
Application Theme
    ↓
Journey Home
```

The shell establishes:

- Material 3
- application theme
- typography
- colors
- surface/card treatment
- navigation structure
- responsive layout foundation
- presentation-layer organization

The UI must not require domain logic to be embedded in widgets.

### 2. Journey Home

The initial screen is the primary product entry point.

It should communicate:

```text
Who am I becoming?
        ↓
Where am I in my journey?
        ↓
What should I do next?
        ↓
What are we learning about me?
```

The initial screen contains a header, Journey progress, a next step, and a growth/understanding section.

### 3. Journey Progress

A prominent Journey card communicates the user's current direction:

```text
YOUR JOURNEY

Becoming Stronger

Become the person you want to be.

████████████████░░░░░  72%

Chapter 3 · Becoming
```

The card represents the Journey rather than a generic progress metric.

### 4. Next Step

The UI presents an immediately actionable next step:

```text
TODAY

YOUR NEXT STEP

Face the Difficult Thing

A small challenge. A meaningful step forward.

             BEGIN
```

This is not merely a task list. The action represents progress toward the person's Journey.

### 5. Growth / Understanding

The Home screen provides a glimpse into what the system is learning about the person:

```text
WHAT WE ARE LEARNING

✦  Consistency

You have been following through
more consistently lately.

3 observations
```

This is deliberately different from a score. The UI should communicate that the system is beginning to understand the person rather than assigning a score.

---

## Navigation

UI.1 establishes the initial navigation model:

```text
┌─────────┬──────────┬───────────┬─────────┐
│  Home   │ Journey  │ Discover  │   Me    │
└─────────┴──────────┴───────────┴─────────┘
```

Only the **Home** experience needs to be fully implemented for UI.1. The other destinations may initially be placeholders.

This establishes the navigation contract without prematurely implementing the entire product.

---

## Visual Language

UI.1 establishes the first Everyone's Heroes design language.

### Foundation

- Dark, warm background
- Elevated dark surfaces
- Warm gold primary accent
- Off-white primary typography
- Muted secondary typography
- Material 3 foundation
- Rounded cards
- Generous spacing
- Large typography
- Minimal visual clutter

### Personality

The experience should feel:

**Purposeful · Personal · Calm · Confident · Human**

It should **not** feel like:

- a generic productivity application
- a fitness tracker
- a traditional RPG
- a social-media feed
- a dashboard full of metrics

The UI should communicate **personal growth**, not gamification for its own sake.

---

## Presentation Architecture

UI.1 establishes:

```text
features/
└── life_journey/
    ├── domain/
    ├── application/
    ├── infrastructure/
    └── presentation/
        ├── screens/
        ├── widgets/
        └── providers/
```

### Screens

Compose complete user experiences, beginning with:

```text
JourneyHomeScreen
```

### Widgets

Provide reusable visual components such as:

```text
JourneyProgressCard
NextStepCard
GrowthPatternCard
```

### Providers

Eventually connect presentation state to application use cases.

UI.1 may initially use static/demo presentation data while corresponding application flows are still being built.

---

## Domain Boundary

The presentation layer **must not become a second domain model**.

We should not duplicate Journey business logic inside presentation models merely for UI convenience.

The intended dependency direction is:

```text
Domain
   ↑
Application
   ↑
Presentation
```

The UI consumes application-facing data and invokes application use cases.

Riverpod may coordinate dependencies and presentation state, but domain objects remain independent of Flutter and Riverpod.

---

## Demo Expectations

UI.1 should be **launchable and demonstrable**.

A person unfamiliar with the codebase should be able to launch the application and immediately see:

```text
Everyone's Heroes
        ↓
Current Journey
        ↓
Progress
        ↓
Next meaningful action
        ↓
Emerging understanding
```

The demo should communicate the product concept without requiring a console demo runner.

`main.dart` should launch the application itself.

The existing `DemoRunner` should no longer be required to demonstrate the UI.

---

## UI.1 Definition of Done

### Application

- [ ] Flutter application launches directly into the Everyone's Heroes UI.
- [ ] `ProviderScope` is established at the application boundary.
- [ ] Material 3 is configured.
- [ ] Application theme is centralized.
- [ ] No console/demo runner is required to launch the UI.

### Presentation Architecture

- [ ] `presentation/` exists under the appropriate feature.
- [ ] Screen/widget responsibilities are separated.
- [ ] Reusable UI components are extracted where appropriate.
- [ ] Flutter dependencies do not leak into the domain layer.
- [ ] Riverpod remains outside the domain layer.

### Journey Home

- [ ] Application header exists.
- [ ] Personalized greeting is displayed.
- [ ] Journey progress card is displayed.
- [ ] Journey vision/direction is represented.
- [ ] Current chapter/progress is represented.
- [ ] Next-step card is displayed.
- [ ] Next-step action is visually actionable.
- [ ] Growth/understanding card is displayed.

### Navigation

- [ ] Bottom navigation exists.
- [ ] Home is the active destination.
- [ ] Journey, Discover, and Me destinations are represented.
- [ ] Navigation architecture can be expanded without restructuring the application.

### Visual Design

- [ ] Application has a consistent color system.
- [ ] Typography is centralized.
- [ ] Cards have a consistent visual treatment.
- [ ] Spacing follows a consistent system.
- [ ] Primary actions have consistent styling.
- [ ] UI communicates the Everyone's Heroes personality.
- [ ] UI does not feel like a generic CRUD/dashboard application.

### Quality

- [ ] `dart analyze` passes.
- [ ] Existing test suite continues to pass.
- [ ] UI code is formatted.
- [ ] `git diff --check` passes.
- [ ] The application can be launched and visually inspected on the development target.

---

## Explicitly Out of Scope

To keep UI.1 focused, these are **not required**:

- Authentication
- User accounts
- Backend APIs
- Production persistence
- Full routing implementation
- Complete Quest UI
- Complete Mission UI
- Reflection UI
- AI coaching UI
- Marketplace
- Hero connections
- Subscription UI
- Notifications
- Social features
- Full Discovery implementation
- Growth Opportunity UI
- Complete responsive/tablet design
- Production accessibility audit
- Production animations
- Final branding/logo system

These can evolve after the initial visual foundation is stable.

---

## The UI.1 Vertical Slice

Ultimately, UI.1 should prove:

```text
                    ┌───────────────┐
                    │ Everyone's    │
                    │ Heroes        │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Journey Home  │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
         Journey        Next Step     Understanding
              │             │             │
              ▼             ▼             ▼
          Progress        Action       Pattern
```

This is the first **product-facing milestone**.

Once UI.1 is complete, we will have something we can actually demonstrate while the deeper behavior engine remains safely frozen at H.2.
