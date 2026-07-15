# Wire the event pipeline (ReflectionSubmitted → AnalyzeReflectionUseCase) to complete the existing architecture.

## Step 1 — Event Handlers

Create an application layer specifically for event handlers.

lib/
└── features/
    └── life_journey/
        └── application/
            ├── handlers/
            │   ├── reflection_submitted_handler.dart
            │   ├── behavioral_evidence_detected_handler.dart
            │   └── mission_completed_handler.dart
            │
            └── use_cases/

Notice these are application objects, not domain objects.

## Step 2 — ReflectionSubmittedHandler

This becomes incredibly small.

final class ReflectionSubmittedHandler
    implements DomainEventHandler<ReflectionSubmitted> {
  ReflectionSubmittedHandler(
    this._analyzeReflectionUseCase,
  );

  final AnalyzeReflectionUseCase _analyzeReflectionUseCase;

  @override
  Future<void> handle(
    ReflectionSubmitted event,
  ) async {
    await _analyzeReflectionUseCase.execute(
      AnalyzeReflectionRequest(
        reflectionId: event.reflectionId,
      ),
    );
  }
}

No business logic.

Just orchestration.

## Step 3 — Event Registration

Instead of having an empty registration class, wire everything here.

Current:

registerHandlers() {
}

Becomes

eventBus.subscribe<ReflectionSubmitted>(
    reflectionSubmittedHandler);

eventBus.subscribe<BehavioralEvidenceDetected>(
    behavioralEvidenceDetectedHandler);

eventBus.subscribe<MissionCompleted>(
    missionCompletedHandler);

Even if the latter two handlers are placeholders for now, the pipeline structure is in place.

## Step 4 — Remove Direct Calls

Anywhere that currently looks like

await submitReflectionUseCase.execute(...);

await analyzeReflectionUseCase.execute(...);

becomes

await submitReflectionUseCase.execute(...);

The event bus takes over from there.
---

# Implement DiscoveryProfile as the central aggregate for personalization.
# Build the deterministic PatternDetector that derives behavior patterns from accumulated BehavioralEvidence.
# Implement GrowthOpportunityDetector to convert patterns into actionable opportunities.

# Create the PersonalizationEngine that consumes the Discovery Profile and produces adaptive experiences.

# Finally, add AI adapters that generate motivational talks, music, lyrics, stories, and coaching based on the deterministic understanding—not the other way aroun