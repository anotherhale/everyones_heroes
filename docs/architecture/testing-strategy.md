# Testing Strategy

This document defines the testing philosophy, priorities, and standards for Everyone's Heroes.

The domain model is the product.

Testing should focus primarily on validating domain behavior rather than UI behavior.

---

# Testing Philosophy

Everyone's Heroes follows:

Domain First Development

Preferred order:

Domain Model
↓
Tests
↓
Use Cases
↓
Infrastructure
↓
UI

Business rules should be validated before presentation concerns.

---

# Testing Priorities

Highest Priority:

1. Aggregates
2. Value Objects
3. Domain Services
4. Use Cases
5. Repository Contracts
6. Event Flows

Lower Priority:

7. Infrastructure Adapters
8. Riverpod Providers
9. UI Components

The domain layer should have the highest test coverage.

---

# Test Pyramid

```
            UI
           /\
          /  \
         /    \
        /      \
 Integration Tests
      /      \
     /        \
    /          \
 Domain Tests
```

Most tests should exist at the domain level.

---

# Aggregate Testing

Every aggregate should have comprehensive behavioral tests.

Test:

* Invariants
* State transitions
* Event generation
* Invalid operations

Do not test:

* Internal implementation details
* Private fields

Test behavior.

---

## Journey Aggregate

Test:

* Creation
* Chapter advancement
* Invalid chapter transitions
* Event publication

Expected Events:

* JourneyCreated
* ChapterAdvanced

---

## Quest Aggregate

Test:

* Creation
* Mission addition
* Mission completion
* Quest completion

Expected Events:

* QuestCreated
* MissionCreated
* MissionCompleted
* QuestCompleted

---

## Reflection Aggregate

Test:

* Creation
* Response collection
* Submission
* Insight addition
* Behavioral Evidence addition
* Narrative Theme addition

Expected Events:

* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded

Important Invariants:

* Responses cannot be modified after submission.
* Reflection must contain at least one response before submission.
* Insights require submission.
* Behavioral Evidence requires submission.
* Narrative Themes require submission.

---

# Value Object Testing

Every value object should validate:

* Equality
* Invariants
* Invalid construction

Examples:

* Insight
* BehavioralEvidence
* NarrativeTheme
* Influence

---

## Equality Testing

All value objects should verify:

```dart
expect(a, equals(b));
expect(a.hashCode, equals(b.hashCode));
```

for equivalent values.

---

## Validation Testing

All invalid construction paths should be tested.

Example:

```dart
expect(
  () => Insight(
    statement: '',
    confidence: 0.8,
  ),
  throwsArgumentError,
);
```

---

# Entity Testing

Entities should validate:

* Construction rules
* Mutation rules
* Invariants

Examples:

* Mission
* Influence
* NarrativeTheme

---

## Influence Tests

Verify:

* Name validation
* Alias management
* Theme ownership
* Theme mutation
* Category assignment

---

# Domain Service Testing

Domain services should be tested independently from aggregates.

Current Services:

* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

Test:

* Input handling
* Output generation
* Error conditions

Avoid:

* Testing AI providers directly

---

# Fake Service Testing

Current fake implementations:

* FakeInsightExtractionService
* FakeBehavioralEvidenceAnalyzer
* FakeNarrativeThemeResolver

These exist to support:

* Use Case tests
* Integration tests

Fake implementations should be deterministic.

The same input should always produce the same output.

---

# Use Case Testing

Every use case should have tests.

Verify:

* Success paths
* Failure paths
* Repository interactions
* Event publication

Current Use Cases:

* CreateJourneyUseCase
* CreateQuestUseCase
* CreateMissionUseCase
* CompleteMissionUseCase
* CreateReflectionUseCase
* SubmitReflectionUseCase
* AnalyzeReflectionUseCase

---

## Use Case Testing Rules

Mock:

* Repositories
* Domain Services

Do not mock:

* Domain Entities
* Value Objects

Use real domain models whenever possible.

---

# Repository Testing

Repository tests should verify contract behavior.

All repository implementations should pass the same contract tests.

Current Repositories:

* JourneyRepository
* QuestRepository
* ReflectionRepository

---

## Repository Contract Requirements

Verify:

* Save
* Update
* Retrieval
* Missing records

Example:

```dart
save()
findById()
findAll()
```

Behavior should remain consistent across implementations.

---

# Event Testing

Every event-producing aggregate should verify:

* Correct event type
* Correct payload
* Correct event count

Example:

```dart
final events = reflection.pullDomainEvents();

expect(events.length, 1);
expect(events.first, isA<ReflectionSubmitted>());
```

---

# Event Pipeline Testing

Current Status:

Partial

Future event orchestration should include integration tests.

Examples:

ReflectionSubmitted
↓
AnalyzeReflectionUseCase

BehavioralEvidenceDetected
↓
Pattern Detection

MissionCompleted
↓
Reflection Recommendation

---

# Integration Testing

Integration tests validate multiple components working together.

Examples:

Reflection
↓
SubmitReflectionUseCase
↓
ReflectionRepository

Reflection
↓
AnalyzeReflectionUseCase
↓
InsightExtractionService
↓
BehavioralEvidenceAnalyzer

Integration tests should verify behavior across boundaries.

---

# Infrastructure Testing

Infrastructure tests should validate:

* Repository implementations
* External adapters
* Serialization

Do not place business rules in infrastructure tests.

Business rules belong in domain tests.

---

# UI Testing

Current Priority:

Low

UI is expected to evolve rapidly during M1.

Focus on:

* Domain correctness
* Architectural stability

before investing heavily in widget testing.

---

# Current Coverage Areas

Covered:

✓ Journey Aggregate

✓ Quest Aggregate

✓ Reflection Aggregate

✓ Reflection Responses

✓ Insight

✓ BehavioralEvidence

✓ NarrativeTheme

✓ Influence

✓ Repository Implementations

✓ Reflection Analysis Services

✓ Reflection Use Cases

---

# Current Testing Gaps

Known gaps:

⚠ Event Pipeline Integration

⚠ DiscoveryProfile Aggregate

⚠ NarrativeThemeRepository

⚠ InfluenceRepository

⚠ Discovery Repositories

⚠ Cross-Context Event Flow

⚠ ReflectionRepository Journey Queries

⚠ Clock-Based Aggregate Testing

These gaps are expected during M1 development.

---

# Test Naming Conventions

Prefer:

```dart
group('Reflection', () {
  test(
    'cannot be submitted without responses',
    () {},
  );
});
```

Over:

```dart
test('test1', () {});
```

Tests should describe business behavior.

---

# Test Data Philosophy

Prefer:

* Real domain objects
* Domain fixtures
* Builders

Avoid:

* Excessive mocking
* Deep stubbing

The closer tests are to real domain behavior, the more valuable they become.

# Architectural Regression Tests

As the platform grows, some tests should exist specifically to protect architectural boundaries.

These tests validate architecture rather than business behavior.

Their purpose is to prevent accidental architectural drift.

---

## Why Architectural Regression Tests Exist

Business tests answer:

"Does the feature work?"

Architectural tests answer:

"Does the system remain correctly designed?"

Both are important.

---

## Domain Isolation Tests

The domain layer must remain independent.

Verify:

* Domain does not depend on Flutter.
* Domain does not depend on Riverpod.
* Domain does not depend on infrastructure adapters.
* Domain does not depend on AI providers.

Forbidden examples:

```dart
import 'package:flutter/...';
```

```dart
import 'package:flutter_riverpod/...';
```

```dart
import 'package:openai/...';
```

inside:

```text
domain/
```

---

## Hexagonal Boundary Tests

Application code may depend on:

* Domain
* Repository Interfaces
* Domain Services

Application code should not depend directly on:

* Databases
* REST APIs
* AI SDKs

Infrastructure code should contain adapter implementations.

---

## AI Isolation Tests

AI is an implementation detail.

Verify:

* Aggregates do not reference AI providers.
* Entities do not reference AI providers.
* Value Objects do not reference AI providers.
* Domain Services are defined as ports.

Examples:

Good:

```text
InsightExtractionService
```

Bad:

```text
OpenAIInsightExtractionService
```

inside the domain layer.

---

## Bounded Context Ownership Tests

Each concept should have a single owner.

Verify:

NarrativeTheme

belongs to:

```text
Discovery
```

and not:

```text
Life Journey
```

Reflection should reference:

```text
NarrativeThemeId
```

not:

```text
NarrativeTheme
```

---

## Aggregate Boundary Tests

Aggregates should not directly mutate other aggregates.

Verify:

Journey
✗ QuestRepository.save()

Reflection
✗ Journey.modify()

Quest
✗ Reflection.addInsight()

Cross-aggregate communication should occur through:

* Use Cases
* Domain Events

---

## Event Architecture Tests

Events should represent facts.

Verify event names use past-tense language.

Examples:

Good:

* ReflectionSubmitted
* QuestCompleted
* BehavioralEvidenceDetected

Bad:

* SubmitReflectionRequested
* GenerateInsightCommand

---

## Evidence-First Architecture Tests

The platform should store observations before interpretations.

Verify:

Reflection
↓
BehavioralEvidence

exists before:

Pattern
↓
Guidance

Avoid architectures that directly generate:

```text
Reflection
    ↓
Score
```

without preserving evidence.

---

## Theme Ownership Tests

Narrative Themes are central to the platform.

Verify:

* NarrativeTheme exists only in Discovery.
* Life Journey references NarrativeThemeId.
* Contribution references NarrativeThemeId.
* Recommendation systems operate through themes.

This prevents duplication of the narrative model.

---

## Future Pattern Detection Tests

When Pattern Detection is introduced:

Verify:

BehavioralEvidence
↓
Pattern

and not:

Reflection
↓
Pattern

Patterns should emerge from evidence.

---

## Future Growth Profile Tests

When Growth Profiles are introduced:

Verify:

Growth belongs to:

Person

rather than:

Journey

A Journey provides context.

Growth belongs to the individual.

---

## Architecture Review Checklist

Before introducing a new concept ask:

1. Is this evidence?
2. Is this a signal?
3. Is this a pattern?
4. Is this guidance?
5. Is this a Narrative Theme?
6. Does this belong to a bounded context?
7. Does this belong to an existing aggregate?
8. Can this be derived instead of stored?
9. Does this violate aggregate boundaries?
10. Does this introduce coupling?

If the answer is unclear, revisit the architecture documents before implementation.

---

## Architectural North Star

Protect:

* Domain isolation
* Hexagonal boundaries
* Event-driven communication
* Narrative Theme ownership
* Evidence-first modeling

Architectural regression tests exist to ensure future features strengthen the architecture rather than slowly erode it.

---

# Continuous Verification

Every pull request should:

```bash
flutter analyze
flutter test
```

before merge.

No failing tests should be committed.

---

# Architectural North Star

The purpose of testing is not coverage.

The purpose of testing is confidence.

Confidence that:

* The domain behaves correctly.
* Business rules remain intact.
* Refactoring is safe.
* Architecture can evolve.

The domain model is the product.

Protect it accordingly.
