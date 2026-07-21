library;

// Aggregate Roots
export 'aggregates/journey.dart';
export 'aggregates/quest.dart';
export 'aggregates/reflection.dart';

// Entities
export 'entities/mission.dart';

// Value Objects
export 'value_objects/pattern.dart';
export 'value_objects/strength.dart';

export 'value_objects/behavioral_evidence.dart';
export 'enums/behavioral_evidence_type.dart';
export 'value_objects/evidence_source.dart';
export 'value_objects/insight.dart';

// Reflection Entities
export 'entities/reflection/reflection_response.dart';
export 'entities/reflection/journal_response.dart';
export 'entities/reflection/prompt_response.dart';
export 'entities/reflection/choice_response.dart';
export 'entities/reflection/emoji_response.dart';
export 'entities/reflection/scale_response.dart';
export 'entities/reflection/voice_response.dart';
export 'entities/reflection/photo_response.dart';

// Domain Events
export 'events/journey_created.dart';
export 'events/chapter_advanced.dart';

export 'events/quest_created.dart';
export 'events/mission_created.dart';
export 'events/mission_completed.dart';
export 'events/quest_completed.dart';

export 'events/reflection_submitted.dart';
export 'events/insights_generated.dart';
export 'events/behavioral_evidence_detected.dart';
export 'events/narrative_themes_added.dart';
export 'events/patterns_detected.dart';

// Domain Services (Ports)
export 'services/insight_extraction_service.dart';
export 'services/behavioral_evidence_analyzer.dart';
export 'services/narrative_theme_resolver.dart';
export 'services/pattern_detector.dart';

// Repository Ports
export 'repositories/journey_repository.dart';
export 'repositories/quest_repository.dart';
export 'repositories/reflection_repository.dart';
