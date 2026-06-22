# Repository Map

This document describes the repository contracts used throughout the Everyone's Heroes domain.

Repositories are domain ports.

Repositories belong to the domain layer.

Implementations belong to the infrastructure layer.

Application services and use cases should depend only on repository interfaces.

---

# Repository Design Principles

Repositories:

* Persist aggregates
* Retrieve aggregates
* Hide storage implementation details

Repositories should not:

* Contain business logic
* Perform orchestration
* Make domain decisions
* Depend on UI frameworks

---

# Life Journey Context

Status: Active

---

## JourneyRepository

Bounded Context:

Life Journey

Aggregate:

Journey

Responsibility:

Persist and retrieve Journey aggregates.

Typical Operations:

```dart
save(Journey journey)

findById(JourneyId id)

findAll()
```

Implementation Status:

✅ Interface Implemented

Current Implementations:

* InMemoryJourneyRepository

Future Implementations:

* SqlJourneyRepository
* IsarJourneyRepository
* FirebaseJourneyRepository

---

## QuestRepository

Bounded Context:

Life Journey

Aggregate:

Quest

Responsibility:

Persist and retrieve Quest aggregates.

Typical Operations:

```dart
save(Quest quest)

findById(QuestId id)

findAll()
```

Implementation Status:

✅ Interface Implemented

Current Implementations:

* InMemoryQuestRepository

Future Implementations:

* SqlQuestRepository
* IsarQuestRepository
* FirebaseQuestRepository

---

## ReflectionRepository

Bounded Context:

Life Journey

Aggregate:

Reflection

Responsibility:

Persist and retrieve Reflection aggregates.

Typical Operations:

```dart
save(Reflection reflection)

findById(ReflectionId id)

findAll()
```

Implementation Status:

✅ Interface Implemented

Current Implementations:

* InMemoryReflectionRepository

Potential Future Operations:

```dart
findByJourneyId(JourneyId id)

findByQuestId(QuestId id)

findSubmitted()
```

These queries are expected to become important for UI and reporting features.

---

# Discovery Context

Status: Foundation

---

## DiscoveryProfileRepository

Bounded Context:

Discovery

Aggregate:

DiscoveryProfile

Responsibility:

Persist and retrieve DiscoveryProfile aggregates.

Implementation Status:

⚠ Planned

Current Implementations:

None

Future Implementations:

* InMemoryDiscoveryProfileRepository
* SqlDiscoveryProfileRepository

---

## InfluenceRepository

Bounded Context:

Discovery

Aggregate:

DiscoveryProfile

Primary Entity:

Influence

Responsibility:

Manage Influence persistence and retrieval.

Implementation Status:

⚠ Planned

Current Implementations:

None

Typical Operations:

```dart
save(Influence influence)

findById(InfluenceId id)

findAll()

searchByName(String query)
```

Notes:

Influence currently exists as an entity.

Repository contract has not yet been created.

---

## NarrativeThemeRepository

Bounded Context:

Discovery

Aggregate:

DiscoveryProfile

Primary Entity:

NarrativeTheme

Responsibility:

Persist and retrieve Narrative Themes.

Implementation Status:

⚠ Interface Stub Exists

Current Implementations:

None

Typical Operations:

```dart
save(NarrativeTheme theme)

findById(NarrativeThemeId id)

findAll()
```

Notes:

Current repository file exists but is largely unimplemented.

---

# Identity Context

Status: Planned

---

## UserRepository

Bounded Context:

Identity

Aggregate:

User

Implementation Status:

○ Future

Potential Operations:

```dart
save(User user)

findById(UserId id)
```

---

## UserProfileRepository

Bounded Context:

Identity

Aggregate:

UserProfile

Implementation Status:

○ Future

Potential Operations:

```dart
save(UserProfile profile)

findByUserId(UserId id)
```

---

# Contribution Context

Status: Planned

---

## ContributionRepository

Bounded Context:

Contribution

Aggregate:

ContributionProfile

Implementation Status:

○ Future

Potential Operations:

```dart
save(ContributionProfile profile)

findById(ContributionId id)
```

---

# Current Infrastructure Implementations

Implemented:

* InMemoryJourneyRepository
* InMemoryQuestRepository
* InMemoryReflectionRepository

Not Yet Implemented:

* Discovery repositories
* Identity repositories
* Contribution repositories

---

# Repository Dependency Rules

Domain Layer

May depend on:

* Repository interfaces

Must not depend on:

* Repository implementations

---

Application Layer

May depend on:

* Repository interfaces

Must not depend directly on:

* Storage technologies

---

Infrastructure Layer

May depend on:

* Domain repositories
* External storage systems

Examples:

* SQLite
* Isar
* Firebase
* REST APIs
* GraphQL APIs

---

# Future Repository Evolution

Current Phase (M1)

Repositories primarily support:

* Aggregate persistence
* Aggregate retrieval

Future Phases

Repositories may support:

* Projections
* Search
* Analytics
* Recommendation queries

These capabilities should be introduced carefully to avoid leaking reporting concerns into aggregate repositories.

---

# Architectural Gaps

Current known gaps:

* DiscoveryProfileRepository not implemented
* InfluenceRepository not implemented
* NarrativeThemeRepository incomplete
* ReflectionRepository lacks journey-oriented queries
* No repository contracts exist for future Identity context
* No repository contracts exist for future Contribution context

These gaps are expected for the current stage of development.

---

# Architectural North Star

Repositories exist to protect the domain.

Application code should depend on:

Aggregate
↓
Repository Interface

never:

Aggregate
↓
Database

The storage mechanism should remain replaceable without affecting domain behavior.
