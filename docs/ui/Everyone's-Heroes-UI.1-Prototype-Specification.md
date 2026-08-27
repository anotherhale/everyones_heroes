# Everyone's Heroes — UI.1 Prototype Specification

**Status:** Anchor Document  
**Phase:** UI.1 — UI Prototype  
**Version:** 1.0  
**Purpose:** Define the product experience, scope, architectural boundaries, and Definition of Done for the first Everyone's Heroes UI prototype.

---

## 1. Purpose

UI.1 is the first concrete user-interface prototype for Everyone's Heroes.

The goal is to make the product vision tangible through a navigable Flutter experience.

UI.1 is **not** intended to be production-complete. It is a prototype used to establish:

- the primary user experience,
- the initial navigation model,
- the major screens,
- the relationship between experience, journey, discovery, and reflection,
- the boundary between UI and the existing domain/application architecture,
- and a stable reference for subsequent UI implementation.

The central question for UI.1 is:

> **What does it feel like to use Everyone's Heroes as a companion for personal growth?**

---

# 2. Product North Star

Everyone's Heroes is an adaptive human growth platform that continuously learns how to inspire each individual.

The product is intentionally oriented toward **transformation rather than attention**.

The intended experience loop is:

```text
Experience
    ↓
Action
    ↓
Reflection
    ↓
Understanding
    ↓
Personalization
    ↓
Growth
    ↓
New Experience
```

The UI should make this loop feel natural.

The user should feel that the application is helping them take a meaningful next step—not simply giving them another destination for consuming content.

---

# 3. UI.1 Goals

UI.1 must demonstrate:

1. A coherent Everyone's Heroes visual and interaction model.
2. A clear primary landing experience.
3. A navigable Journey experience.
4. An ongoing Discovery experience.
5. A Reflection experience.
6. A user-facing representation of what the system is learning.
7. The relationship between these experiences.
8. A clean boundary between the UI and the domain/application layers.

UI.1 does **not** need to implement the complete adaptive-growth platform.

---

# 4. UI.1 Non-Goals

The following are explicitly outside the UI.1 prototype scope:

- Production authentication
- Subscription/payment flows
- Hero marketplace
- Social/community features
- Production AI generation
- Production recommendation/personalization engine
- Production notifications
- Production backend integration
- Complete persistence implementation for all UI state
- Production analytics
- Complete visual design system
- Advanced animation
- Production accessibility certification
- Complete responsive design for every platform

These may be addressed by later phases.

UI.1 should use mock/static data where necessary to demonstrate the intended experience.

---

# 5. Core Experience Model

The broader Everyone's Heroes model is:

```text
Discovery
    ↓
Experience
    ↓
Action
    ↓
Reflection
    ↓
Behavioral Evidence
    ↓
Behavior Patterns
    ↓
Discovery Profile
    ↓
Personalization
    ↓
Adaptive Experience
    ↓
Growth
```

UI.1 does not need to implement every stage.

It must establish the user-facing experience that can eventually support the complete loop.

---

# 6. Fundamental UI Principle

> **The user experiences transformation; the architecture records understanding.**

The user experiences concepts such as:

- Experience
- Action
- Reflection
- Discovery
- Journey
- Encouragement
- Growth
- What the system is learning

The architecture internally manages concepts such as:

- Aggregates
- Entities
- Value Objects
- Behavioral Evidence
- Behavior Patterns
- Domain Events
- Repositories
- Application Use Cases
- Reactors
- Providers

Internal architectural terminology should not automatically become user-facing terminology.

For example, the UI should not primarily present:

```text
BehaviorPattern
Strength: 0.72
ObservationCount: 7
```

Instead, the user may eventually see:

```text
You've been showing a strong tendency
to follow through, even when things
become difficult.
```

---

# 7. Primary Navigation

UI.1 uses four primary destinations:

```text
┌────────────────────────────────────────────┐
│                                            │
│              CURRENT SCREEN                │
│                                            │
│                                            │
│                                            │
├────────────────────────────────────────────┤
│  Home    Journey    Discover    Reflect    │
└────────────────────────────────────────────┘
```

## Navigation Requirements

- The application launches to Home.
- Home, Journey, Discover, and Reflect are directly reachable.
- Back navigation behaves normally.
- Navigation should remain simple.
- UI.1 should avoid unnecessary navigation depth.
- Navigation must not become a substitute for product design.

Understanding may initially be reachable from Home or Journey rather than occupying a permanent navigation destination.

---

# 8. Screen: Home / Today

## Purpose

Home is the primary entry point.

It should answer:

> **What should I do right now?**

The experience should feel:

- personal,
- calm,
- encouraging,
- purposeful,
- and action-oriented.

## Conceptual Layout

```text
Good morning.

You don't have to change everything today.
Just take the next step.

────────────────────────────────

TODAY'S EXPERIENCE

[ Experience / encouragement ]

[ Begin Experience ]

────────────────────────────────

YOUR JOURNEY

[ Continue Journey ]

────────────────────────────────

DISCOVER

[ Learn Something About Yourself ]

────────────────────────────────

REFLECT

[ Reflect on an Experience ]
```

## Requirements

- Personalized-looking greeting.
- Clearly identifiable Today's Experience.
- One obvious primary action.
- Journey entry point.
- Discovery entry point.
- Reflection entry point.

The Today's Experience may be static/mock content in UI.1.

The prototype is demonstrating the experience, not the future personalization implementation.

---

# 9. Screen: Journey

## Purpose

Journey represents the person's ongoing hero journey.

It should communicate continuity, progress, and meaning.

It should **not** feel like a project-management dashboard.

## Conceptual Layout

```text
                 YOUR JOURNEY

                      ●
                     /                     /                      ●     ●
                  /                        ●         ○
                /
               ●

        Chapter 1
        Finding Your Strength

        4 quests completed
        3 reflections
        2 patterns discovered
```

The exact visual representation is intentionally open.

## Journey May Represent

- Current chapter
- Milestones
- Active quest/mission
- Reflections
- Progress
- Emerging understanding

The UI should present these as part of a personal journey rather than raw aggregate state.

---

# 10. Screen: Discover

## Purpose

Discovery is an ongoing process of learning what inspires an individual.

Discovery is **not** intended to be a large one-time personality questionnaire.

The experience should feel conversational and progressive.

## Example

```text
Let's discover what inspires you.

Think of someone who has influenced
the person you've become.

Who comes to mind?

[____________________________]

[ Continue ]
```

Future Discovery may explore:

- Heroes
- People
- Stories
- Music
- Books
- Movies
- Quotes
- Values
- Goals
- Experience preferences
- Coaching preferences
- Storytelling preferences

UI.1 only needs to demonstrate the interaction pattern.

## Requirements

Discovery should feel:

- Natural
- Progressive
- Personal
- Conversational
- Purposeful

Do not implement a large questionnaire merely to populate the prototype.

---

# 11. Screen: Reflect

## Purpose

Reflection allows the user to make meaning from an experience.

Reflection is an important source of information for the existing behavioral-understanding architecture.

The UI should nevertheless present Reflection as a personal activity rather than an evidence-generation workflow.

## Conceptual Flow

### Step 1

```text
What happened?

Tell us about something
you experienced today.

[____________________________]

[ Continue ]
```

### Step 2

```text
How did it feel?

[ response options ]

[ Continue ]
```

### Step 3

```text
What did you learn about yourself?

[____________________________]

[ Complete Reflection ]
```

The exact questions are prototype content.

Future adaptive reflection may eventually consider:

- Current mission
- Mission type
- Journey stage
- Existing behavioral understanding
- Growth opportunities
- Discovery information
- Historical evidence

UI.1 does not implement that adaptive engine.

---

# 12. Screen: Understanding

## Purpose

Understanding communicates what Everyone's Heroes is learning about the individual.

This is the user-facing representation of the system's growing understanding.

It must remain human-readable.

## Conceptual Layout

```text
WHAT WE'RE LEARNING ABOUT YOU

You keep showing up.

Even when something is difficult,
you've demonstrated a tendency
to follow through.

────────────────────────────────

CONSISTENCY

You've demonstrated this
repeatedly across your journey.

────────────────────────────────

You care deeply about others.

Your experiences suggest that
helping people is important to
what motivates you.
```

This is a prototype representation.

The eventual underlying flow may be:

```text
Behavioral Evidence
        ↓
Behavior Patterns
        ↓
Growth Opportunities
        ↓
Discovery Profile
```

The UI should not expose those implementation details as the primary experience.

---

# 13. User Experience Principles

## 13.1 Personal

The experience should feel relevant to the individual without pretending the system knows more than it actually does.

Avoid generic dashboard language when a personal interaction is possible.

## 13.2 Encouraging

Everyone's Heroes exists to inspire.

Avoid judgmental language, competitive scoring, or language that makes the user feel evaluated.

## 13.3 Narrative

The user is on a hero's journey.

The UI should communicate:

- where they have been,
- where they are,
- what they have learned,
- and what comes next.

## 13.4 Progressive

Do not expose the entire system at once.

Reveal complexity as the relationship with the application develops.

## 13.5 Human

Internal terminology does not automatically become UI terminology.

Suggested conceptual translation:

| Internal Concept | User-Facing Concept |
|---|---|
| Behavioral Evidence | What happened / What you demonstrated |
| Behavior Pattern | Something we're noticing |
| Growth Opportunity | An opportunity / A next step |
| Discovery Profile | What we're learning about you |
| Personalization Engine | Not exposed |
| Adaptive Experience | Today's Experience / Your next experience |

---

# 14. Architecture Boundary

UI.1 must respect the existing Everyone's Heroes architecture.

The dependency direction remains:

```text
Presentation / UI
       ↓
Application
       ↓
Domain
       ↓
Infrastructure
```

The UI must not:

- directly manipulate aggregates,
- contain domain business rules,
- construct domain events as a shortcut,
- bypass application use cases,
- access repositories directly when an application abstraction exists,
- or duplicate domain behavior inside widgets.

UI state and presentation concerns belong in the presentation/application boundary.

Domain behavior remains in the domain layer.

---

# 15. Relationship to H.2

H.2 establishes the current behavioral-understanding foundation.

The UI should consume that foundation rather than redesign it.

Conceptually:

```text
User Experience
      │
      ▼
Reflection
      │
      ▼
Application
      │
      ▼
Journey / Domain
      │
      ▼
Behavioral Evidence
      │
      ▼
Behavior Patterns
```

The UI.1 prototype may use mocked results to demonstrate the eventual user experience.

H.2 behavior must remain stable while UI.1 is implemented unless a separate architectural decision is made.

---

# 16. Prototype Data Strategy

UI.1 may use mock data.

The purpose of mock data is to demonstrate:

- screen composition,
- navigation,
- interaction,
- visual hierarchy,
- user-facing language,
- and the relationship between screens.

Mock data should be structured so that replacing it with application-layer data later does not require rewriting the UI architecture.

Avoid embedding large amounts of fake domain logic directly into widgets.

---

# 17. Testing Strategy

UI.1 should add tests for the user-visible behavior that matters.

At minimum:

### Navigation

- App launches to Home.
- Primary destinations can be reached.
- Navigation transitions work.

### Home

- Home renders the primary experience.
- Primary CTA is present.
- Journey, Discovery, and Reflection entry points are present.

### Journey

- Journey renders.
- Current journey state is represented.

### Discovery

- Discovery prompt renders.
- User can enter/progress through the prototype interaction.

### Reflection

- Reflection interaction renders.
- User can enter a response.
- Completion state is reachable.

### Understanding

- User-facing understanding content renders.
- Raw internal behavioral-analysis objects are not required as UI text.

Existing H.2 tests must continue to pass.

---

# 18. Definition of Done

UI.1 is complete when all of the following are true.

## Product Experience

- [ ] The app launches into a coherent Home experience.
- [ ] The user can navigate through Home, Journey, Discover, and Reflect.
- [ ] Today's Experience is represented.
- [ ] Journey is represented as an ongoing personal story.
- [ ] Discovery feels like an ongoing interaction rather than a questionnaire.
- [ ] Reflection can be completed through the prototype.
- [ ] The user can see a human-readable representation of what the system is learning.

## Architecture

- [ ] UI code remains outside the domain layer.
- [ ] Widgets do not contain domain business rules.
- [ ] UI does not directly manipulate aggregates.
- [ ] Application-layer abstractions are used where appropriate.
- [ ] Mock data can be replaced by real application data without redesigning the screen architecture.

## Quality

- [ ] `dart analyze` passes.
- [ ] Existing tests remain passing.
- [ ] UI tests cover the major prototype flows.
- [ ] The application runs on the intended Flutter target.
- [ ] No UI.1 work introduces an unnecessary architectural dependency.

## Product Judgment

- [ ] The prototype feels like a personal-growth experience rather than an administrative dashboard.
- [ ] The user understands what to do next.
- [ ] The UI communicates encouragement rather than evaluation.
- [ ] The relationship between Experience, Journey, Discovery, and Reflection is understandable without knowing the underlying architecture.

---

# 19. Explicitly Deferred Decisions

The following decisions are intentionally deferred until after the UI.1 prototype:

- Final branding
- Final typography
- Final color palette
- Final iconography
- Production animation system
- AI experience generation
- Personalization algorithms
- Recommendation algorithms
- Social features
- Marketplace design
- Subscription UX
- Production authentication UX
- Production notification UX
- Full accessibility system
- Complete responsive-layout strategy

UI.1 should establish the product experience without prematurely locking these decisions.

---

# 20. Implementation Sequence

UI.1 should be implemented in the following order:

```text
1. Establish UI shell
       ↓
2. Establish navigation
       ↓
3. Build Home
       ↓
4. Build Journey
       ↓
5. Build Discover
       ↓
6. Build Reflect
       ↓
7. Build Understanding
       ↓
8. Add UI tests
       ↓
9. Run full validation
       ↓
10. Review prototype against this document
```

The document is the anchor.

If implementation decisions conflict with this document, either:

1. change the implementation to conform, or
2. explicitly update this document through a deliberate decision.

Do not allow the implementation to silently redefine the product.

---

# 21. UI.1 Success Criteria

UI.1 succeeds if someone unfamiliar with the codebase can launch the prototype and understand:

1. **What Everyone's Heroes is.**
2. **What they are supposed to do today.**
3. **That they are on a personal journey.**
4. **That the system is gradually learning about them.**
5. **That their reflections contribute to that understanding.**
6. **That future experiences can become increasingly personal.**

The prototype does not need to prove that the entire platform works.

It needs to make the vision believable.

---

# 22. Anchor Statement

All UI.1 implementation decisions should be evaluated against this statement:

> **Everyone's Heroes should feel like a companion that helps a person take the next meaningful step in their own hero's journey.**

If a UI feature increases complexity but does not improve that experience, it should be questioned.

If a UI feature exposes internal architecture without improving the user's understanding, it should be questioned.

If a UI feature makes the product feel more like a generic productivity, social, or content application, it should be questioned.

The prototype exists to establish the experience of Everyone's Heroes—not merely to put screens around the existing code.
