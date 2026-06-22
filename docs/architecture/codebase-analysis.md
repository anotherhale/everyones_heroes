---
Codebase Analysis: Everyone's Heroes

---
1. Current Bounded Contexts

┌──────────────┬───────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┐
│   Context    │                         State                         │ion                         │
├──────────────┼───────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Life Journey │ Active — primary context, partially mid-refactor      │ lib/features/life_journey/ │
├──────────────┼───────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Discovery    │ Skeleton — entities exist, aggregate is an empty file │                            │
├──────────────┼───────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Identity     │ Not started — only UserId in core/ids                 │                            │
├──────────────┼───────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
│ Contribution │ Not started — only ContributionId in core/ids         │                            │
└──────────────┴───────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────┘

---
2. Aggregate Roots

┌──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│    Aggregate     │                              File                               │                                       Status                                        │
├──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Journey          │ lib/features/life_journey/domain/aggregates/journey.dart        │ ✅ Implemented                                                                      │
├──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Quest            │ lib/features/life_journey/domain/aggregates/quest.dart          │ ✅ Implemented (owns Mission internally)                                            │
├──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Reflection       │ lib/features/life_journey/domain/aggregates/reflection.dart     │ ✅ Implemented                                                                      │
├──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ LifeJourney      │ —                                                               │ ❌ Missing — CLAUDE.md defines it as the root above Journey; only LifeJourneyId     │
│                  │                                                                                                                          │
├──────────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
│ DiscoveryProfile │ lib/features/discovery/domain/aggregates/discovery_(0 bytes)                                                             │
└──────────────────┴─────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────┘

---
3. Domain Events

┌────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│           Event            │                      File                      │ Aggregate  │                                    Status                                     │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ JourneyCreated             │ domain/events/journey_created.dart             │ Journey    │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ChapterAdvanced            │ domain/events/chapter_advanced.dart            │ Journey    │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ QuestCreated               │ domain/events/quest_created.dart               │ Quest      │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ QuestCompleted             │ domain/events/quest_completed.dart             │ Quest      │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ MissionCreated             │ domain/events/mission_created.dart             │ Quest      │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ MissionCompleted           │ domain/events/mission_completed.dart           │ Quest      │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ReflectionSubmitted        │ domain/events/reflection_submitted.dart        │ Reflection │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ InsightsGenerated          │ domain/events/insights_generated.dart          │ Reflection │ ✅                                                                            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ BehavioralEvidenceDetected │ domain/events/behavioral_signals_observed.dart │ Reflection │ ⚠️ Implemented but filename is wrong (behavioral_signals_observed)            │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ BehavioralSignalGenerated  │ domain/events/behavioral_signal_generated.dart │ Journey    │ ⚠️ Orphaned — raised by no aggregate; should be deprecated per AD-005         │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ NarrativeThemesAdded       │ —                                              │ —          │ ❌ Missing — addNarrativeThemes() on Reflection silently adds themes without  │
│                            │                                          any event                                                             │
└────────────────────────────┴────────────────────────────────────────────────┴────────────┴───────────────────────────────────────────────────────────────────────────────┘

---
4. Use Cases

The use case layer is split across two competing homes mid-refactor:

lib/contexts/life_journey/application/ (old location, still referenced b
- CreateJourneyUseCase — implements UseCase<> interface
- CreateQuestUseCase — does not implement UseCase<> interface
- CreateMissionUseCase — does not implement UseCase<> interface
- CompleteMissionUseCase — does not implement UseCase<> interface
- SubmitReflectionUseCase — does not implement UseCase<> interface

lib/features/life_journey/application/ (new location, partially migrated):
- AnalyzeReflectionUseCase — does not implement UseCase<> interface; hasalEvidenceAnalyzer — uppercase private field)
- use_cases/CreateReflectionUseCase — does not implement UseCase<> interface

The UseCase<Request, Response> interface exists in contexts/life_journey/application/use_case.dart but only CreateJourneyUseCase implements it.

---
5. Repository Interfaces

┌────────────────────────────┬─────────────────────────────────────────────────────────────────────┐
│         Repository         │                    Location                    │                     Status                      │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ JourneyRepository          │ lib/features/life_journey/domain/repositories/ │ ✅ Complete                                     │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ QuestRepository            │ lib/features/life_journey/domain/repositories/ │ ✅ Complete                                     │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ ReflectionRepository       │ lib/features/life_journey/domain/repositories/ │ ✅ Complete — no findByJourneyId, likely needed │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ NarrativeThemeRepository   │ lib/features/discovery/domain/repositories/    │ ❌ Empty file (0 bytes)                         │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ InfluenceRepository        │ —                                              │ ❌ Missing entirely                             │
├────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ DiscoveryProfileRepository │ —                                              │ ❌ Missing entirely                             │
└────────────────────────────┴─────────────────────────────────────────────────────────────────────┘

---
6. Infrastructure Implementations

Repositories (in-memory only):
- InMemoryJourneyRepository — plain class (not final)
- InMemoryQuestRepository — plain class (not final)
- InMemoryReflectionRepository — final class ✅

Domain Service Fakes (test doubles in production lib/ — should be in tes
- FakeBehavioralEvidenceAnalyzer — lib/features/.../infrastructure/services/fake/
- FakeInsightExtractionService — lib/features/.../infrastructure/service
- FakeNarrativeThemeResolver — lib/features/.../infrastructure/services/fake/

No real AI adapters exist — the ports (InsightExtractionService, BehavioralEvidenceAnalyzer, NarrativeThemeResolver) are defined as abstract interface class in
lib/features/life_journey/infrastructure/services/. Note: these interfacrastructure/.

---
7. Architectural Drift from CLAUDE.md

Critical:

1. Dual use case location — refactor incomplete. Five use cases remain in lib/contexts/life_journey/application/ while two newer ones landed in
lib/features/life_journey/application/. Both paths are active and testedmigration source; it was never cleaned up.
2. LifeJourney aggregate root is absent. CLAUDE.md defines the hierarchy as LifeJourney → Journey → Quest → Mission. Only LifeJourneyId exists — the aggregate root that is
supposed to sit above Journey was never implemented.
3. Domain service ports live in infrastructure/, not domain/. InsightExtractionService, BehavioralEvidenceAnalyzer, and NarrativeThemeResolver are defined in
lib/features/life_journey/infrastructure/services/. They are ports (outgthe domain) and should live inlib/features/life_journey/domain/services/.
4. Event pipeline is completely empty. EventPipelineRegistration.registes event-driven cross-context communication, but no event handlers arewired — ReflectionSubmitted, BehavioralEvidenceDetected, and MissionCompleted have no subscribers.
5. GrowthSignal-era artifacts remain in test/. test/features/life_journe_generated_test.dart tests BehavioralSignalGenerated (renamed but thefile kept its old name). test/features/life_journey/domain/fixtures/growth_signal_fixture.dart is an empty stub. AD-005 says not to introduce new growth signal usages; the
test file title is misleading.

Moderate:

6. BehavioralSignal entity is orphaned. behavioral_signal.dart defines a a BehavioralSignalType. It is imported by nothing in lib/ and appearsonly in its own test. The BehavioralSignalType enum itself is still used by BehavioralEvidence, creating naming confusion (evidence references a type named after the
deprecated signal concept).
7. addNarrativeThemes() raises no domain event. addInsights() raises InsightsGenerated and addbehavioralEvidence() raises BehavioralEvidenceDetected, but addNarrativeThemes()
 silently mutates state without publishing. This breaks the audit trail.
8. behavioral_signals_observed.dart contains BehavioralEvidenceDetected. The filename is a leftover from a rename that was not completed.
9. UseCase<> interface applied inconsistently. Only CreateJourneyUseCase use cases are bare classes.
10. Reflection.create() calls DateTime.now() directly. The shared kernel has Clock, SystemClock, and FixedClock abstractions. The aggregate bypasses them, making the creation
 timestamp untestable.
11. Fake service adapters are in lib/, not test/. FakeBehavioralEvidenceAnalyzer, FakeInsightExtractionService, and FakeNarrativeThemeResolver are shipped in production code
under lib/features/.../infrastructure/services/fake/.
12. DependencyRegistration uses mutable static state (service locator). This is not true dependency injection, is shared across test runs, and would require careful reset
between tests. Inconsistent with the hexagonal architecture goal.

---
8. Missing Tests

┌──────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                         Missing Test                         │              Why it Matters                                           │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Reflection.addNarrativeThemes() does not raise an event      │ Silent  gap                                                           │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ CreateQuestUseCase persists journey with attached quest      │ The usest() and saves both aggregates; only quest-side save is tested │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ReflectionRepository.findByJourneyId                         │ Method  be needed by UI                                               │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DiscoveryProfile aggregate                                   │ File is                                                               │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ NarrativeThemeRepository contract                            │ Interfas                                                              │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ InfluenceRepository contract                                 │ No inte                                                               │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ EventPipelineRegistration wiring                             │ Currentvents trigger handlers                                         │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Clock injection into Reflection.create()                     │ DateTimaking submission time non-deterministic in tests               │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ growth_signal_fixture.dart                                   │ Empty s                                                               │
├──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Integration: ReflectionSubmitted → AnalyzeReflection trigger │ End-to-o integration test across the event boundary                   │
└──────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────┘

---
9. Potential Architectural Issues

1. Non-atomic save + publish. All use cases save the aggregate first, thIf any eventBus.publish() call throws, the state is committed butdownstream handlers never run. The domain can become inconsistent with no recovery path.
2. BehavioralEvidence couples to BehavioralSignalType. The value object ls still references BehavioralSignalType — the enum from the deprecatedmodel. As the system grows this will become a naming liability. Consider renaming to BehavioralTraitType or EvidenceType.
3. BehavioralSignal entity + BehavioralSignalGenerated event are dead coested, but no aggregate ever raises BehavioralSignalGenerated andBehavioralSignal is attached to nothing. They are either being retained for future pattern detection (undocumented intent) or are leftover artifacts — either way, the intent
should be documented or the code removed.
4. Discovery context has no aggregate boundary enforcement. Influence is an Entity but not behind an aggregate root (DiscoveryProfile is empty). Anything can mutate Influence
 directly. The invariant that "Influence must have at least one Narrativtity itself, but without a repository or aggregate root there is nopersistence boundary.
5. No findByJourneyId on ReflectionRepository. The natural query of "sho journey" has no port defined. When the UI layer consumes the domain this will require an interface change, a migration of in-memory storage, and likely test additions — all deferred technical debt.
6. InMemoryJourneyRepository and InMemoryQuestRepository are not final. is final class. The inconsistency allows unintended subclassing of thein-memory stores, which can produce silent test-isolation problems.
7. Service locator (DependencyRegistration) with static mutable state. Sr, _eventBus are reset only when null. If tests initialize these in oneorder and don't reset, state bleeds between test suites. This is not flagged by any test currently.
8. AnalyzeReflectionUseCase has an uppercase private field (_BehavioralEtion is lowerCamelCase for all identifiers. The constructor parameter isalso BehavioralEvidenceAnalyzer (capital B), which shadows the type name. This will cause a linting error with prefer_final_fields and is a readability hazard.

✻ Baked for 5m 5s

※ recap: Analyzed the Everyone's Heroes codebase for architectural drift and incomplete refactoring. The analysis is complete and ready to review. Next step is to decide which drift items to address first, likely consolidating use cases from contexts/ into features/. (disable recaps in /config)
