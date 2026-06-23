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
│ BehavioralEvidenceDetected │ domain/events/behavioral_evidence_detected.dart │ Reflection │ ✅ Implemented; filename corrected (was behavioral_signals_observed — DRIFT-002 resolved) │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ BehavioralSignalGenerated  │ domain/events/behavioral_signal_generated.dart │ Journey    │ ⚠️ Orphaned — raised by no aggregate; deprecated per AD-005 (see DRIFT-008)  │
├────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ NarrativeThemesAdded       │ domain/events/narrative_themes_added.dart      │ Reflection │ ✅ Implemented — addNarrativeThemes() publishes the event (DRIFT-001 resolved) │
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

Last updated: 2026-06-22

Resolved since initial analysis:

✅ DRIFT-001: addNarrativeThemes() now publishes NarrativeThemesAdded.
✅ DRIFT-002: behavioral_signals_observed.dart renamed to behavioral_evidence_detected.dart.

Critical (open):

1. Dual use case location — refactor incomplete (DRIFT-004). Five use cases remain in lib/contexts/life_journey/application/ while two newer ones landed in lib/features/life_journey/application/. Both paths are active and tested. The contexts/ path is the old migration source; it was never cleaned up.
2. LifeJourney aggregate root is absent. Only LifeJourneyId exists — the aggregate root above Journey was never implemented.
3. Domain service ports live in infrastructure/, not domain/ (DRIFT-003). InsightExtractionService, BehavioralEvidenceAnalyzer, and NarrativeThemeResolver are defined in lib/features/life_journey/infrastructure/services/. They are ports and should live in lib/features/life_journey/domain/services/.
4. Event pipeline is completely empty. EventPipelineRegistration registers no handlers — ReflectionSubmitted, BehavioralEvidenceDetected, and MissionCompleted have no subscribers.
5. GrowthSignal-era artifacts remain (DRIFT-008). behavioral_signal_generated.dart defines BehavioralSignalGenerated; no aggregate raises it. behavioral_signal.dart entity is imported by nothing in lib/. growth_signal_generated_test.dart and growth_signal_fixture.dart are misleadingly named artifacts of the deprecated model.

Moderate (open):

6. BehavioralSignal entity is orphaned (DRIFT-008). behavioral_signal.dart is imported by nothing. BehavioralSignalType enum is still used by BehavioralEvidence, creating naming confusion (evidence references a type named after the deprecated signal concept).
7. UseCase<> interface applied inconsistently. Only CreateJourneyUseCase implements it; all other use cases are bare classes.
8. Reflection.create() calls DateTime.now() directly. The shared kernel has Clock, SystemClock, and FixedClock abstractions. The aggregate bypasses them, making the creation timestamp non-deterministic in tests (TD-007).
9. Fake service adapters are in lib/, not test/ (DRIFT-007). FakeBehavioralEvidenceAnalyzer, FakeInsightExtractionService, and FakeNarrativeThemeResolver are shipped in production code under lib/features/.../infrastructure/services/fake/.
10. DependencyRegistration uses mutable static state (DRIFT-006). This is a service locator pattern, not true dependency injection.
11. behavioral_evidencel_analyzer.dart has a filename typo (DRIFT-009). The 'l' between 'evidence' and '_analyzer' is incorrect.

---
8. Missing Tests

Current test count: 386 passing (as of 2026-06-22)

Still missing:

- CreateQuestUseCase: does not verify journey persistence (only quest-side save is tested)
- ReflectionRepository.findByJourneyId: no port or test exists
- DiscoveryProfile aggregate: file is 0 bytes; no tests
- NarrativeThemeRepository contract: interface is 0 bytes; no tests
- InfluenceRepository contract: interface missing entirely
- EventPipelineRegistration wiring: no handlers are registered; no integration tests
- Clock injection into Reflection.create(): DateTime.now() called directly; timestamp non-deterministic
- growth_signal_fixture.dart: empty stub; should be removed or replaced
- Integration: ReflectionSubmitted → AnalyzeReflection trigger (end-to-end event boundary)
- BehavioralSignalGenerated orphan: test file growth_signal_generated_test.dart covers a deprecated concept

---
9. Potential Architectural Issues

1. Non-atomic save + publish. All use cases save the aggregate first, then publish events. If eventBus.publish() throws, state is committed but downstream handlers never run. The domain can become inconsistent with no recovery path.
2. BehavioralEvidence couples to BehavioralSignalType. The value object still references BehavioralSignalType — the enum from the deprecated model. As the system grows this will become a naming liability. Consider renaming to BehavioralTraitType or EvidenceType.
3. BehavioralSignalGenerated event and BehavioralSignal entity are dead code. No aggregate ever raises BehavioralSignalGenerated and BehavioralSignal is attached to nothing. These are leftover artifacts from the GrowthSignal → BehavioralEvidence migration (see DRIFT-008).
4. Discovery context has no aggregate boundary enforcement. Influence is an Entity but not behind an aggregate root (DiscoveryProfile is 0 bytes). Anything can mutate Influence directly. There is no persistence boundary (see DRIFT-005).
5. No findByJourneyId on ReflectionRepository. The natural query of "show reflections for a journey" has no port defined. When the UI layer consumes the domain this will require an interface change, a migration of in-memory storage, and likely test additions (TD-008).
6. InMemoryJourneyRepository and InMemoryQuestRepository are not final. InMemoryReflectionRepository is final. The inconsistency allows unintended subclassing.
7. Service locator (DependencyRegistration) with static mutable state. State bleeds between test suites if not reset. This is not flagged by any test currently (DRIFT-006).
8. AnalyzeReflectionUseCase has an uppercase private field (_BehavioralEvidenceAnalyzer). Dart convention is lowerCamelCase for all identifiers. The constructor parameter also shadows the type name.
